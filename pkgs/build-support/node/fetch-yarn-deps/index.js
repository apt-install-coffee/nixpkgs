#!/usr/bin/env node
'use strict'

const fs = require('fs')
const crypto = require('crypto')
const process = require('process')
const https = require('https')
const child_process = require('child_process')
const path = require('path')
const lockfile = require('./yarnpkg-lockfile.js')
const { promisify } = require('util')

const execFile = promisify(child_process.execFile)

const lockFile = fs.readFileSync(process.argv[2] || 'yarn.lock', 'utf8')
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

const downloadFileHttps = (fileName, url, expectedHash) => {
	return new Promise((resolve, reject) => {
		https.get(url, (res) => {
			const file = fs.createWriteStream(fileName)
			const hash = crypto.createHash('sha1')
			res.pipe(file)
			res.pipe(hash).setEncoding('hex')
			res.on('end', () => {
				file.close()
				const h = hash.read()
				if (h != expectedHash) return reject(new Error(`hash mismatch, expected ${expectedHash}, got ${h}`))
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

const downloadPkg = pkg => {
	const [ url, hash ] = pkg.resolved.split('#')
	console.log('downloading ' + url)
	if (url.startsWith('https://codeload.github.com/') && url.includes('/tar.gz/')) {
		const fileName = path.basename(url)
		const s = url.split('/')
		downloadGit(fileName, `https://github.com/${s[3]}/${s[4]}.git`, s[6])
	} else if (url.startsWith('https://')) {
		const fileName = url
			.replace(/https:\/\/(.)*(.com)\//g, '') // prevents having long directory names
			.replace(/[@/%:-]/g, '_') // replace @ and : and - and % characters with underscore

		return downloadFileHttps(fileName, url, hash)
	} else if (url.startsWith('git+')) {
		const fileName = path.basename(url)
		return downloadGit(fileName, url.replace(/^git\+/, ''), hash)
	} else {
		throw new Error('don\'t know how to download "' + url + '"')
	}
}

const worker = async () => {
	let next
	while (next = pkgs.shift()) {
		await downloadPkg(next)
	}
}

const workers = []
for (let i = 0; i < 16; i++) {
	workers.push(worker())
}

Promise.all(workers)
	.then(() => console.log('Done'))
	.catch(e => {
		console.error(e)
		process.exit(1)
	})
