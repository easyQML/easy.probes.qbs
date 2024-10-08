<!--
SPDX-FileCopyrightText: © 2024 Serhii “GooRoo” Olendarenko

SPDX-License-Identifier: BSD-3-Clause
-->

# easy.probes for Qbs

[![Made by Ukrainian](https://img.shields.io/static/v1?label=Made%20by&message=Ukrainian&labelColor=1f5fb2&color=fad247&style=flat-square)](https://savelife.in.ua/en/donate-en/#donate-army-card-once)
[![License](https://img.shields.io/github/license/easyQML/easy.probes.qbs?style=flat-square)](LICENSE)
![REUSE Compliance](https://img.shields.io/reuse/compliance/github.com%2FeasyQML%2Feasy.probes.qbs?style=flat-square)

A collection of helper probes for your Qbs projects.

## Available probes

### `ConanInstall`

This probe for Conan 2 runs `conan install` before building the project.

#### Dependencies

- Qbs ≥ 2.4
- Conan ≥ 2.4

#### Usage

1. Enable the conan provider in your project:
    ```qml
	Project {
		qbsModuleProviders: ['conan']
	}
	```
2. Set the install directory for it in **all your products:**
	```qml
	moduleProviders.conan.installDirectory: project.buildDirectory
	```
	Unfortunately, this can't be done on a project level yet due to the [QBS-1801](https://bugreports.qt.io/browse/QBS-1801).
3. Use it in your project. For example, like this:
	```qml
	import qbs.FileInfo
	import easy.probes as Easy

	Project {
		qbsModuleProviders: ['conan']

		Easy.ConanInstall {
			id: conan
			conanfilePath: FileInfo.joinPaths(project.sourceDirectory, 'conanfile.py')

			compilerCppStd: 20
			additionalArguments: ['--build=missing']
		}
	}
	```
