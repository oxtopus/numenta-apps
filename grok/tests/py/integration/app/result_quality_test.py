#!/usr/bin/env python
# ----------------------------------------------------------------------
# Numenta Platform for Intelligent Computing (NuPIC)
# Copyright (C) 2015, Numenta, Inc.  Unless you have purchased from
# Numenta, Inc. a separate commercial license for this software code, the
# following terms and conditions apply:
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# http://numenta.org/licenses/
# ----------------------------------------------------------------------

"""
Integration tests for Grok output quality.
"""

import json
import logging
import socket
import time
# Make sure we're using the same version of unttest as our base class
from grok.test_utils.app.test_case_base import unittest
import csv
import os
import uuid

import requests

import datetime
from dateutil.parser import parse as parsedate

from nta.utils import amqp
from nta.utils.date_time_utils import epochFromNaiveUTCDatetime

from htmengine.runtime.anomaly_service import AnomalyService
from grok import logging_support
from grok.app import config
from grok.test_utils.app import test_case_base
from grok.test_utils.app.confusion_matrix import WindowedConfusionMatrix



LOGGER = logging.getLogger(__name__)



def setUpModule():
  logging_support.LoggingSupport.initTestApp()



def genConfusionMatrix(recordLabels,
                       resultData,
                       threshold = 0.99,
                       window = 30,
                       windowStepSize = 5):
  """
  Returns a confusion matrix object for the results of the
  given experiment and the ground truth labels.

  :param experiment: an experiment info dict
  :param threshold: cutoff to be applied to Likelihood scores
  :type threshold: float
  :param window: Use a WindowedConfusionMatrix and calculate stats over
                 this many minutes.
  :param windowStepSize: The ratio of minutes to records
  """

  likelihoodScores = [row[2] for row in resultData]

  # If likelihood is ABOVE threshold, label it an anomaly, otherwise not
  predicted = map(lambda x: 1 if x > threshold else 0, likelihoodScores)
  actual = recordLabels

  if not windowStepSize:
    raise Exception("windowStepSize must be at least 1")

  cMatrix = WindowedConfusionMatrix(predicted,
                                    actual,
                                    window,
                                    windowStepSize)

  return cMatrix



class ResultQualityTests(test_case_base.TestCaseBase):
  """
  Tests the output of Grok with known data.
  """


  def setUp(self):
    self.plaintextPort = config.getint("metric_listener", "plaintext_port")
    self.apiKey = config.get("security", "apikey")

    self.initialLoggingString = "Running result quality test using metric: %s"

    # Subscribe to results broadcast from Anomaly Service

    connParams = amqp.connection.getRabbitmqConnectionParameters()

    def deleteAmqpQueue(queue):
      with amqp.synchronous_amqp_client.SynchronousAmqpClient(connParams) as (
          amqpClient):
        amqpClient.deleteQueue(queue=queue, ifUnused=False, ifEmpty=False)

    self.resultsQueueName = "grok.result_quality_test.likelihood_results.%s" % (
      uuid.uuid1().hex,)

    with amqp.synchronous_amqp_client.SynchronousAmqpClient(connParams) as (
          amqpClient):
      amqpClient.declareQueue(self.resultsQueueName)
      self.addCleanup(deleteAmqpQueue, self.resultsQueueName)

      amqpClient.bindQueue(
        queue=self.resultsQueueName,
        exchange=config.get("metric_streamer", "results_exchange_name"),
        routingKey="#")


  def testIIOData(self):
    """
    Tests for expected result quality from IIO data

    1246 rows
    """

    dataIdentifier = "IIO"
    knownDataFile = "iio_us-east-1_i-a2eb1cd9_NetworkIn.csv"
    expectedResults = {"fn": 5,
                       "fp": 10,
                       "tn": 885,
                       "tp": 0,
                       "quality": -550}

    results1 = self._runQualityTest(dataIdentifier, knownDataFile,
                                    expectedResults)

    # Run it one more time and make sure results are consistent
    results2 = self._runQualityTest(dataIdentifier, knownDataFile,
                                    expectedResults)
    self.fastCheckSequenceEqual(results1, results2)


  def testRNSData(self):
    """
    Tests for expected result quality from RNS data.

    4030 rows
    """

    dataIdentifier = "RNS"
    knownDataFile = "rns_Backend_InstanceId=i-57009237_DiskWriteOps.csv"
    expectedResults = {"fn": 3,
                       "fp": 8,
                       "tn": 3683,
                       "tp": 2,
                       "quality": -230}

    self._runQualityTest(dataIdentifier, knownDataFile, expectedResults)


  def testGrokRPMBuildData(self):
    """
    Grok RPM Build Caught Anomaly - Network In

    7428 rows
    """
    dataIdentifier = "GRK"
    knownDataFile = "grok_rpmbuild_realanomaly_networkIn.csv"
    expectedResults = {"fn": 48,
                       "fp": 58,
                       "tn": 7130,
                       "tp": 141,
                       "quality": 10720}

    self._runQualityTest(dataIdentifier, knownDataFile, expectedResults)


  def _genUniqueMetricName(self, datasetName):
    """
    Adds the initial logging message for each test
    """
    runIdentifier = str(time.time())
    metricName = "test.metric.%s.%s" % (datasetName, runIdentifier)

    return metricName


  def _getPathToData(self, filename):
    """
    Returns the absolute path to a file that lives in the relative data/
    directory.
    """
    basePath = os.path.split(os.path.abspath(__file__))[0]
    dataDirPath = os.path.join(basePath, 'data')

    knownDataFilePath = os.path.join(dataDirPath, filename)

    return knownDataFilePath


  @classmethod
  def _loadDataGen(cls, filePath):
    """ Yields (dttm, value, label) three-tuples from the given dataset

    :param filePath: The csv with data
    """
    with open(filePath, "r") as fh:
      reader = csv.reader(fh)

      # Skip headers
      next(reader)
      next(reader)
      next(reader)

      for (dttm, value, label) in reader:
        yield (dttm, value, label)


  def _loadAndSendData(self, sock, filePath, metricName):
    """
    Returns the list of labels from the csv at filePath. Date and value
    fields are sent to the metric specified. As a side effect this
    creates the metric.

    :param sock: A connected socket object
    :param filePath: The csv with data to handle
    :param metricName: The target custom metric we will send data to
    """
    labels = []
    for (dttm, value, label) in self._loadDataGen(filePath):
      # Parse date string
      dttm = parsedate(dttm)
      # Convert to seconds since epoch (Graphite wants this)
      dttm = epochFromNaiveUTCDatetime(dttm)
      dttm = int(dttm)

      #LOGGER.info("{TAG:CLIENT.METRIC} metric=%s:%s:%s", metricName, dttm,
      #            value)

      # Add data
      sock.sendall("%s %r %s\n" % (metricName, float(value), dttm))

      # Save the label for use later
      # Convert strings to appropriate numerical type
      try:
        labels.append(int(label))
      except ValueError:
        labels.append(float(label))

    self.gracefullyCloseSocket(sock)

    return labels


  def _getSocketConnection(self):
    """
    Returns a socket connected to localhost. This is a small abstraction in case
    this changes in the future.
    """

    # Create our socket connection to the metric listener
    sock = socket.socket()
    sock.connect(("localhost", self.plaintextPort))

    return sock


  def _createModel(self, uid):
    """
    Sends the API request to create a model. This is a small abstraction
    in case of change.
    """
    payload = {"uid": uid, "datasource": "custom"}
    requests.post("https://localhost/_models",
                  auth=(self.apiKey, ""), verify=False,
                  data=json.dumps(payload))


  def _reapAnomalyServiceResults(self, metricId, numRowsExpected):
    """ Retrieve likelihood results from our AMQP message queue that is bound to
    Anomaly Service's results topic exchange

    :param metricId: unique id of our metric/model
    :param numRowsExpected: number of result rows expected by caller

    :returns: a sequence of dicts conforming to the schema of the results items
      per model_inference_results_msg_schema.json
    """
    rows = []

    @test_case_base.retry(duration=30)
    def getBatch(amqpClient):
      message = amqpClient.getOneMessage(self.resultsQueueName, noAck=False)

      try:
        self.assertIsNotNone(message)
      except AssertionError:
        LOGGER.info("Got %d rows so far, waiting for %d more",
                    len(rows), numRowsExpected - len(rows))
        raise

      return message


    connParams = amqp.connection.getRabbitmqConnectionParameters()
    with amqp.synchronous_amqp_client.SynchronousAmqpClient(
        amqp.connection.getRabbitmqConnectionParameters()) as amqpClient:

      lastMessage = None

      while len(rows) < numRowsExpected:
        message = getBatch(amqpClient)

        lastMessage = message
        batch = AnomalyService.deserializeModelResult(message.body)

        dataType = (message.properties.headers.get("dataType")
                    if message.properties.headers else None)

        if dataType:
          continue # Not a model inference result

        # batch is a dict compliant with model_inference_results_msg_schema.json

        if batch["metric"]["uid"] != metricId:
          # Another model's result
          continue

        # Extract data rows; each row is a dict from the "results" attribute per
        # model_inference_results_msg_schema.json
        rows.extend(batch["results"])


      lastMessage.ack(multiple=True)

    return rows


  def _verifyResults(self,
                     uid,
                     metricName,
                     knownDataFilePath,
                     labels,
                     expectedResults,
                     boundingRange = .1):
    """
    Waits for the model to complete running through the data up to lastRowId
    and then computes a confusion matrix over all the results and
    compares those values to the pre-calculated expectedResults.

    :param uid: The uid of the metric / model
    :param metricName: name of custom metric
    :param lastRowId: The count of rows in the data / expected count of results
    :param labels: The ground truth labels for each row of data.
    :param expectedResults: A dict containing pre-computed confusion matrix
                            results
    :param boundingRange: The allowable deviation from the values in
                          ``expectedResults``. Exceeding this range will fail
                          the test

    :returns: A sequence of results from the model; each result is a sequence of
      <Date string>, <Value>, <Likelihood Score>,  <Record Number>
    """

    # data is a list of rows like this:
    # Date - Value - Anomaly Likelihood* - Record Number
    # e.g. [u'2013-08-31 00:20:00', 405.8, 0.135666, 1440]
    # * Due to a naming error this is CALLED "Anomaly Score" in the db but
    # in reality is that it is the likelihood score.
    lastRowId = len(labels)
    data = self.getModelResults(uid, lastRowId)

    # We get this back from the API backwards
    data.reverse()

    with open("results.%s.csv" % (metricName,), "w") as fh:
      writer = csv.writer(fh)
      writer.writerow(("timestamp", "metric_value", "likelihood", "rowid"))
      writer.writerows(data)

    # Retrieve results broadcast by Anomaly Service and compare against known
    # data
    anomalyServiceResults = self._reapAnomalyServiceResults(
      metricId=uid,
      numRowsExpected=len(labels))

    # Fix up timestamps for compatibility with our known data and for saving to
    # csv file
    for row in anomalyServiceResults:
      row["ts"] = (datetime.datetime.utcfromtimestamp(row["ts"])
                   .strftime("%Y-%m-%d %H:%M:%S"))

    # Write out the results for debugging
    with open("anomsvc.%s.csv" % (metricName,), "w") as fh:
      writer = csv.writer(fh)
      attributes = sorted(anomalyServiceResults[0].keys())

      # Write the header row
      writer.writerow(attributes)

      # Write the data rows
      for row in anomalyServiceResults:
        fields = tuple(row[attr] for attr in attributes)
        writer.writerow(fields)

    # Compare timestamp and value sequence in results against known data
    knownData = tuple((ts, float(value)) for ts, value, _label in
      self._loadDataGen(knownDataFilePath))
    dataFromGrokApi = tuple((ts, value) for ts, value, _, _ in data)
    self.fastCheckSequenceEqual(dataFromGrokApi, knownData)

    # Compare data from grok-api results with AMQP-dispatched data from Anomaly
    # Service
    places = 9
    dataFromAnomalyService = tuple(
      (row["ts"], row["value"],
       round(row["anomaly"], places), row["rowid"])
      for row in anomalyServiceResults)
    dataFromGrokApi = tuple(
      (ts, value, round(score, places), rowid)
      for ts, value, score, rowid in data)
    self.fastCheckSequenceEqual(dataFromGrokApi, dataFromAnomalyService)

    # Compute the confusion matrix
    cMatrix = genConfusionMatrix(labels, data)

    def formatMessage(statusMessage):
      substitutions = dict(expectedResults)
      substitutions.update({
        "statusMessage": statusMessage,
        "boundingRange": boundingRange,
        "afn": cMatrix.fn,
        "afp": cMatrix.fp,
        "atn": cMatrix.tn,
        "atp": cMatrix.tp,
        "aquality": cMatrix.quality})
      message = ("%(statusMessage)s\n"
                 "Expected:\n"
                 "    False negatives: %(fn)i\n"
                 "    False positives: %(fp)i\n"
                 "    True negatives:  %(tn)i\n"
                 "    True positives:  %(tp)i\n"
                 "    Quality Score:   %(quality)i\n"
                 "Actual:\n"
                 "    False negatives: %(afn)i\n"
                 "    False positives: %(afp)i\n"
                 "    True negatives:  %(atn)i\n"
                 "    True positives:  %(atp)i\n"
                 "    Quality Score:   %(aquality)i\n") % substitutions
      return message

    for (key, value) in expectedResults.iteritems():
      actual = getattr(cMatrix, key)
      spread = value * boundingRange
      # We don't call these 'upper' and 'lower' bounds because if value is
      # negative it reverses the expected order of inequality
      boundA = value - spread
      boundB = value + spread

      failMessage = formatMessage(
        "Change in %s - %.2f boundary violation." %
        (key, boundingRange))

      self.assertTrue((boundA <= actual <= boundB) or
                      (boundB <= actual <= boundA),
                      failMessage)

    passingMessage = formatMessage("%s Passed with %.2f boundary." %
                                   (self, boundingRange,))
    LOGGER.info(passingMessage)

    return data


  def _runQualityTest(self, dataIdentifier, knownDataFile, expectedResults):
    """
    Runs the data from knownDataFile (a csv) through Grok and verifies Grok
    returns the expected values in terms of a confusion matrix dict
    expectedResults.

    :param dataIdentifier: A string to identify this data in logs
    :param knownDataFile: A csv filename that exist in local data/ dir
    :param expectedResults: The confusion matrix and quality score we expect
                            out of grok.
    :type expectedResults: dict

    :returns: A sequence of results from the model; each result is a sequence of
      <Date string>, <Value>, <Likelihood Score>,  <Record Number>
    """

    metricName = self._genUniqueMetricName(dataIdentifier)

    self.addCleanup(requests.delete,
                    "https://localhost/_metrics/custom/%s" % metricName,
                    auth=(self.apiKey, ""), verify=False)

    LOGGER.info(self.initialLoggingString, metricName)

    # Get path to data
    knownDataFilePath = self._getPathToData(knownDataFile)

    # Load and send data
    sock = self._getSocketConnection()
    LOGGER.info("Sending data from %s ...", knownDataFile)
    labels = self._loadAndSendData(sock, knownDataFilePath, metricName)

    # Make sure the metric was properly created and wait for the expected
    # records to be stored. NOTE: Waiting for all records to be stored
    # facilitates constistent stats calculation in Grok, resulting in
    # consistency of results from one run of the test to the next.
    uid = self.checkMetricCreated(metricName, numRecords=len(labels))

    # Save the uid for later
    LOGGER.info("Metric %s has uid: %s", metricName, uid)

    # Send model creation request
    self._createModel(uid)

    return self._verifyResults(uid, metricName, knownDataFilePath, labels,
                               expectedResults)



if __name__ == "__main__":
  unittest.main()
