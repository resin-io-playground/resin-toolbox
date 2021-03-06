Promise = require('bluebird')
_ = require('lodash')
Docker = require('docker-toolbelt')
form = require('resin-cli-form')
chalk = require('chalk')

module.exports =

	selectContainerFromDevice: Promise.method (deviceIp) ->
		docker = new Docker(host: deviceIp, port: 2375)

		docker.listContainersAsync()
		.then (containers) ->
			if _.isEmpty(containers)
				throw new Error("No containers are running in #{deviceIp}")

			return form.ask
				message: 'Select a container'
				type: 'list'
				choices: _.map containers, (container) ->
					return {
						name: "#{container.Names[0] or 'Untitled'} (#{container.Id})"
						value: container.Id
					}

	pipeContainerStream: Promise.method ({ deviceIp, name, outStream, follow = false }) ->
		docker = new Docker(host: deviceIp, port: 2375)

		docker.getContainer(name).attachAsync
			logs: not follow
			stream: follow
			stdout: true
			stderr: true
		.then (containerStream) ->
			containerStream.pipe(outStream)
		.catch (err) ->
			err = '' + err.statusCode
			if err is '404'
				return console.log(chalk.red.bold("Container '#{name}' not found."))
			throw err

