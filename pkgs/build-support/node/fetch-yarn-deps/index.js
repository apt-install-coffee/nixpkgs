#!/usr/bin/env node
'use strict'

const fs = require('fs')
const https = require('https')
const child_process = require('child_process')
const path = require('path')
const lockfile = require('./yarnpkg-lockfile.js')
const { promisify } = require('util')

const execFile = promisify(child_process.execFile)

const lockFile = fs.readFileSync(process.argv[2], 'utf8')
const lockData = lockfile.parse(lockFile)

const pkgs = Object.values(
	Object.entries(lockData.object)
	.map(([key, value]) => {
		return { key, ...value }
	})
	.reduce((out, pkg) => {
		out[pkg.resolved] = pkg
		return out
	}, {})
)

const urlToName = url => {
	const isCodeloadGitTarballUrl = url.startsWith('https://codeload.github.com/') && url.includes('/tar.gz/')

	if (url.startsWith('git+') || isCodeloadGitTarballUrl) {
		return path.basename(url)
	}

	return url
		.replace(/https:\/\/(.)*(.com)\//g, '') // prevents having long directory names
		.replace(/[@/%:-]/g, '_') // replace @ and : and - and % characters with underscore
}

const downloadFileHttps = (fileName, url, hash) => {
	return new Promise((resolve, reject) => {
		https.get(url, (res) => {
			const file = fs.createWriteStream(fileName)
			res.pipe(file)
			file.on('finish', () => {
				file.close()
				resolve()
			})
		}).on('error', e => reject(e))
	})
}

const downloadGit = async (fileName, url, rev) => {
	let res

	res = await execFile('nix-prefetch-git', [
		'--out', fileName + '.tmp',
		'--url', url,
		'--rev', rev,
		'--builder'
	])
	if (res.error) throw new Error(res.stderr)

	res = await execFile('tar', [
		// hopefully make it reproducible across runs and systems
		'--owner=0', '--group=0', '--numeric-owner', '--format=gnu', '--sort=name', '--mtime=@1',

		// Set u+w because tar-fs can't unpack archives with read-only dirs: https://github.com/mafintosh/tar-fs/issues/79
		'--mode', 'u+w',

		'-C', fileName + '.tmp',
		'-cf', fileName, '.'
	])
	if (res.error) throw new Error(res.stderr)

	res = await execFile('rm', [ '-rf', fileName + '.tmp', ])
	if (res.error) throw new Error(res.stderr)
}

const worker = async () => {
	let next
	while (next = pkgs.shift()) {
		const [ url, hash ] = next.resolved.split('#')
		console.log('downloading ' + url)
		const fileName = urlToName(url)
		if (url.startsWith('https://')) {
			await downloadFileHttps(fileName, url, hash)
		} else if (url.startsWith('git+')) {
			await downloadGit(fileName, url.replace(/^git\+/, ''), hash)
		}
	}
}

const workers = []
for (let i = 0; i < 16; i++) {
	workers.push(worker())
}

Promise.all(workers)
	.then(() => console.log('Done'))
