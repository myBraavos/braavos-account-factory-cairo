# Braavos Account Factory

The Braavos Account Factory is a smart contract designed to simplify the deployment of a Consumer Braavos Account from an INVOKE transaction.
It allows the account to be initialized with advanced Braavos Account Abstraction features atomically at the time of deployment.
This enables use-cases such as sponsoring account deployments while retaining the ability to deploy Braavos Accounts with maximum security (2FA / 3FA) and other advanced Account Abstraction features by default.

## Deployments

Contract is deployed on both Starknet Sepolia and Mainnet:
* Class hash: ```0x04effebdc377ef61843da355d3cef05d863a99a2978c64fd24c4709e6aaeac21```
* Address: ```0x3d94f65ebc7552eb517ddb374250a9525b605f25f4e41ded6e7d7381ff1c2e8```

## Why is it needed?

Unlike ETH or BTC addresses, which are derived from the account's public key, Starknet accounts are smart contracts (native Account Abstraction), and their addresses are affected by constructor parameters.

For simple accounts initialized with a Stark public key, this is not an issue since the only constructor parameter is the public key.
This means that an account address is fully recoverable from the seed phrase and account index used to derive the public key.

However, Braavos Accounts, with advanced Account Abstraction features, have initialization parameters that may not be related to the seed phrase and are generally not recoverable.
A notable example is the Hardware Signer public key, which is bound to a specific mobile device's secure hardware.
If that device is lost, there is no way to recover the address from its seed phrase.
For non-deployed accounts, this is even more complicated since there is no on-chain trace for the account, making it impossible to recover from events emitted when setting the Stark public key.

To avoid losing track of such account addresses and avoid using centralized solutions to keep track of account addresses,
we need a way to provide these "non-recoverable" parameters atomically right after the account constructor is called.
This is what this contract achieves.

## Braavos Account Support

The factory supports Braavos Accounts that implement the `initializer_from_factory` entrypoint (version >= `001.001.000`).

## API

```deploy_braavos_account(stark_pub_key: felt252, additional_deployment_params: Span<felt252>) -> ContractAddress```

#### Parameters
```stark_pub_key```
> The Stark public key used to initialize the Account (usually derived from the seed phrase)

```additional_deployment_params```
> A raw list of parameters used to initialize the different account features. Note that 
> the Braavos Account expects the last 3 parameters to be the chain-id and a signature on the
> ```poseidon``` hash over all the parameters using the stark key corresponding to ```stark_pub_key```
>
> * For dApp use-cases (such as sponsoring deployments), the parameters can be used as-is when obtained via
> [wallet_deploymentData](https://github.com/starknet-io/types-js/blob/76a31d51b7a6254b28f75cab3ace272dfea72e25/src/wallet-api/methods.ts#L106)
>
> * For other use-cases it should be noted that the list of parameters depends on 
> the supported features of the specific class hash being deployed. The latest deployment parameters
> are defined in `AdditionalDeploymentParams` in [braavos-account-cairo](https://github.com/myBraavos/braavos-account-cairo/blob/main/src/account/interface.cairo)
>

#### Return value
Returns the address of the newly deployed Braavos Account
