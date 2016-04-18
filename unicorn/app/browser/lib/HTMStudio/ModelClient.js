// Numenta Platform for Intelligent Computing (NuPIC)
// Copyright (C) 2015, Numenta, Inc.  Unless you have purchased from
// Numenta, Inc. a separate commercial license for this software code, the
// following terms and conditions apply:
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero Public License version 3 as
// published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Affero Public License for more details.
//
// You should have received a copy of the GNU Affero Public License
// along with this program.  If not, see http://www.gnu.org/licenses.
//
// http://numenta.org/licenses/

import {ipcRenderer as ipc} from 'electron';

import ModelErrorAction from '../../actions/ModelError';
import ReceiveModelDataAction from '../../actions/ReceiveModelData';
import StopModelAction from '../../actions/StopModel';

const MODEL_SERVER_IPC_CHANNEL = 'MODEL_SERVER_IPC_CHANNEL';


/**
 * HTM Studio: ModelClient - Talk to a ModelService over IPC, gaining
 *  access to the Backend NuPIC Model Runner. Connects via IPC adapter.
 */
export default class ModelClient {

  constructor() {
    this._context = null;
    this._lastActionEvent = 0;
    this._dataBuffer = new Map();
  }

  start(actionContext) {
    this._context = actionContext;
    ipc.on(MODEL_SERVER_IPC_CHANNEL, this._handleIPCEvent.bind(this));
  }

  createModel(modelId, inputOpts, aggOpts, modelOpts) {
    ipc.send(MODEL_SERVER_IPC_CHANNEL, {
      modelId,
      command: 'create',
      inputOpts: JSON.stringify(inputOpts),
      aggOpts: JSON.stringify(aggOpts),
      modelOpts: JSON.stringify(modelOpts)
    });
  }

  removeModel(modelId) {
    ipc.send(MODEL_SERVER_IPC_CHANNEL, {
      modelId,
      command: 'remove'
    });
  }

  _handleIPCEvent(event, modelId, command, payload) {
    if (this._context) {
      if (command === 'data') {
        setTimeout(() => this._handleModelData(modelId, payload));
      } else if (command === 'error') {
        let {error, ipcevent} = payload;
        setTimeout(() => this._handleIPCError(modelId, error, ipcevent));
      } else if (command === 'close') {
        setTimeout(() => this._handleCloseModel(modelId ,payload));
      } else {
        console.error(`Unknown command: ${command} ${payload}`); // eslint-disable-line
      }
    }
  }

  _handleIPCError(modelId, error, ipcevent) {
    let command;

    if (ipcevent) {
      if ('command' in ipcevent) {
        command = ipcevent.command;
      }
    }

    this._context.executeAction(ModelErrorAction, {command, modelId, error});
  }

  _handleCloseModel(modelId, error) {
    if (error !== 0) {
      this._context.executeAction(ModelErrorAction, {
        modelId,
        command: 'close',
        error: `Error closing model ${error}`
      });
    } else {
      // Flush model data
      this._flush(modelId);
      // Stop model
      this._context.executeAction(StopModelAction, modelId);
    }
  }

  _flush(modelId) {
    if (modelId) {
      if (this._dataBuffer.has(modelId)) {
        let data = this._dataBuffer.get(modelId);
        this._dataBuffer.delete(modelId);
        this._context.executeAction(ReceiveModelDataAction, {modelId, data});
      }
    } else {
      // Flush all pending data
      for (let [modelId, data] of this._dataBuffer) {
        this._context.executeAction(ReceiveModelDataAction, {modelId, data});
      }
      this._dataBuffer.clear();
    }
  }

  _handleModelData(modelId, payload) {
    // Multiple data records are separated by `\n`
    let data = payload.trim().split('\n').map((row) => {
      if (row) {
        return  JSON.parse(row);
      }
    });

    // Add data to buffer
    if (!this._dataBuffer.has(modelId)) {
      this._dataBuffer.set(modelId, []);
    }
    this._dataBuffer.get(modelId).push(...data);

    // Flush data every 200 ms
    let now = Date.now();
    if (now > this._lastActionEvent + 200) {
      this._lastActionEvent = now;
      this._flush();
    }
  }
}
