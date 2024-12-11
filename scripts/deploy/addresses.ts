import * as fs from 'fs'
import * as path from 'path'
import { DeployNetwork } from '../deloyProtocol'
import { Hex } from 'viem'

interface AddressBook {
  [network: string]: {
    [key: string]: string
  }
}
export type EcoChainConfig = {
  Prover: Hex
  IntentSource: Hex
  Inbox: Hex
  HyperProver: Hex
}

export const PRE_SUFFIX = '-pre'
export const jsonFilePath = path.join(
  __dirname,
  '../../build/deployAddresses.json',
)
export const tsFilePath = path.join(__dirname, '../../build/src/index.ts')
export const csvFilePath = path.join(
  __dirname,
  '../../build/deployAddresses.csv',
)
export function createJsonAddresses() {
  if (fs.existsSync(jsonFilePath)) {
    console.log('Addresses file already exists: ', jsonFilePath)
  } else {
    console.log('Creating addresses file: ', jsonFilePath)
    fs.writeFileSync(jsonFilePath, JSON.stringify({}), 'utf8')
  }
}

export function mergeAddresses(ads: Record<string, EcoChainConfig>){
  let addresses: Record<string, EcoChainConfig> = {}

  if (fs.existsSync(jsonFilePath)) {
    const fileContent = fs.readFileSync(jsonFilePath, 'utf8')
    addresses = JSON.parse(fileContent)
  }
  
  addresses = {...addresses, ...ads}
  fs.writeFileSync(jsonFilePath, JSON.stringify(addresses), 'utf8')
}

/**
 * Adds a new address to the address json file
 * @param deployNetwork the network of the deployed contract
 * @param key the network id
 * @param value the deployed contract address
 */
export function updateAddress(
  deployNetwork: DeployNetwork,
  key: string,
  value: string,
) {
  let addresses: AddressBook = {}

  if (fs.existsSync(jsonFilePath)) {
    const fileContent = fs.readFileSync(jsonFilePath, 'utf8')
    addresses = JSON.parse(fileContent)
  }
  const ck = deployNetwork.chainId.toString()
  const chainKey = deployNetwork.pre ? ck + PRE_SUFFIX : ck
  addresses[chainKey] = addresses[chainKey] || {}
  addresses[chainKey][key] = value
  fs.writeFileSync(jsonFilePath, JSON.stringify(addresses), 'utf8')
}


/**
 * Transforms the addresses json file into a typescript file
 * with the correct imports, exports, and types.
 */
export function transformAddresses() {
  const name = 'EcoProtocolAddresses'
  const addresses = JSON.parse(fs.readFileSync(jsonFilePath, 'utf-8'))
  const importsExports = `import {Hex} from 'viem'\nexport * from './abi'\n`
  const types = `/**
 * The eco protocol chain configuration type. Represents
 * all the deployed contracts on a chain.
 * 
 * @packageDocumentation
 * @module index
 */
export type EcoChainConfig = {
  Prover: Hex
  IntentSource: Hex
  Inbox: Hex
  HyperProver: Hex
}

/**
 * The chain ids for the eco protocol
 * 
 * @packageDocumentation
 * @module index
 */
export type EcoChainIds = ${formatAddressTypes(addresses)}\n\n`
  const comments = `/**
 * This file contains the addresses of the contracts deployed on the EcoProtocol network
 * for the current npm package release. The addresses are generated by the deploy script.
 * 
 * @packageDocumentation
 * @module index
*/
`
  const outputContent =
    importsExports +
    types +
    comments +
    `export const ${name}: Record<EcoChainIds, EcoChainConfig> = \n${formatObjectWithoutQuotes(addresses, 0, true)} as const\n`
  fs.writeFileSync(tsFilePath, outputContent, 'utf-8')
}

// This function formats an object with quotes around the keys and indents per level by 2 spaces
function formatAddressTypes(obj: Record<string, any>): string {
  return Object.keys(obj)
    .map((key) => `"${key}"`)
    .join(' | ')
}

// This function formats an object without quotes around the keys and indents per level by 2 spaces
function formatObjectWithoutQuotes(
  obj: Record<string, any>,
  indentLevel = 0,
  rootLevel = false,
): string {
  const indent = ' '.repeat(indentLevel * 2) // 2 spaces per level
  const nestedIndent = ' '.repeat((indentLevel + 2) * 2)

  const formatValue = (value: any): string => {
    if (typeof value === 'object' && value !== null)
      return formatObjectWithoutQuotes(value, indentLevel + 1) // Recursive with increased indent
    return JSON.stringify(value) // For numbers, arrays, etc.
  }

  const entries = Object.entries(obj)
    .map(([key, value]) => {
      return `${nestedIndent}"${key}": ${formatValue(value)}`
    })
    .join(',\n')
  const frontIndent = rootLevel ? '  ' : ''
  return `${frontIndent}{\n${entries}\n${indent}  }`
}
