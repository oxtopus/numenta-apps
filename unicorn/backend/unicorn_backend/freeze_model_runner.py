# ----------------------------------------------------------------------
# Numenta Platform for Intelligent Computing (NuPIC)
# Copyright (C) 2015, Numenta, Inc.  Unless you have purchased from
# Numenta, Inc. a separate commercial license for this software code, the
# following terms and conditions apply:
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero Public License for more details.
#
# You should have received a copy of the GNU Affero Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# http://numenta.org/licenses/
# ----------------------------------------------------------------------

import cx_Freeze
import pyproj
import os



def getRequirements(requirementsPath):
  """
  Return a list of requirements based on a requirements.txt file.
  :param requirementsPath: path to the requirements.txt file
  :return installRequires: list of requirements
  """

  installRequires = []
  dependencyLinks = []
  with open(requirementsPath, "r") as reqFile:
    for line in reqFile:
      line = line.strip()
      (link, _, package) = line.rpartition("#egg=")
      if link:
        # e.g., "-e https://github.com/.../master#egg=haigha-0.7.4rc100"
        if line.startswith("-e"):
          line = line[2:].strip()

        dependencyLinks.append(line)

        (packageName, _, packageVersion) = package.partition("-")

        package = packageName + "==" + packageVersion

      installRequires.append(package)

  return installRequires



def generate_zip_includes(base_path, directory_name):
  """
  Generate a list of tuples where the fist element is the original 
  path and the second element the target path to the file to include in the 
  zipped library of packages generated by cx_freeze.
  :param base_path: path to the parent dir of the package to include in the zip.
  :param directory_name: target directory name.
  """
  skip_count = len(base_path.split(os.sep))
  zip_includes = [(base_path, directory_name)]
  for root, sub_folders, files in os.walk(base_path):
    for file_in_root in files:
      zip_includes.append(
        (os.path.join(root, file_in_root),
         os.path.join(directory_name,
                      os.sep.join(root.split(os.sep)[skip_count:]),
                      file_in_root)))
  return zip_includes



def main():
  """
  Package the model runner. Warning: This assumes that this script is in the 
  same directory as model_runner.py.
  """
  # Initial cleanup.
  modelRunnerDir = os.path.dirname(os.path.realpath(__file__))
  buildDir = os.path.join(modelRunnerDir, "build")
  distDir = os.path.join(modelRunnerDir, "dist")
  nupicDir = os.path.join(modelRunnerDir, "nupic")
  os.system("rm -rf build %s %s %s" % (buildDir, distDir, nupicDir))

  # Install nupic locally, using the version listed in requirements.txt, and 
  # include it in the library.zip generated by cx_freeze.
  requirementsPath = os.path.join(os.path.join(modelRunnerDir, os.pardir),
                                  "requirements.txt")
  requirements = getRequirements(requirementsPath)
  nupicPackage = "nupic"  # if nupic req is not listed, get the latest version.
  for requirement in requirements:
    if "nupic" in requirement:
      nupicPackage = requirement
      break
  nupicInstall = ("pip install --target %s %s"
                  % (os.path.join(modelRunnerDir, "nupic"), nupicPackage))
  os.system(nupicInstall)
  zipIncludes = generate_zip_includes(os.path.join(modelRunnerDir,
                                                   "nupic", "nupic"), "nupic")

  # Include the Pyproj data folder. Data files are not found by cx_freeze 
  # automatically so you need to tell it where to find it.
  includeFiles = ([(pyproj.pyproj_datadir, os.path.join("pyproj", "data"))] +
                  [(os.path.join(modelRunnerDir, "stats_schema.json"),
                    "stats_schema.json")])

  print includeFiles
  # Freeze the model runner
  executables = [cx_Freeze.Executable(os.path.join(modelRunnerDir,
                                                   "model_runner.py"),
                                      targetName="model_runner")]

  freezer = cx_Freeze.Freezer(executables,

                              namespacePackages=["nupic",
                                                 "prettytable"],
                              zipIncludes=zipIncludes,
                              includeFiles=includeFiles,
                              silent=True)

  freezer.Freeze()

  # final cleanup
  os.system("rm -rf %s" % nupicDir)



if __name__ == "__main__":
  main()
