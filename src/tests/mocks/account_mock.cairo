use starknet::ClassHash;

#[derive(Copy, Drop, Serde, starknet::Store, PartialEq)]
pub struct MockDeploymentParams {
    pub class_hash: ClassHash,
    pub mock1: felt252,
    pub mock2: felt252,
    pub mock3: (felt252, felt252),
}


#[starknet::interface]
pub trait IMockFirstTimeInit<TState> {
    fn initializer_from_factory(
        ref self: TState, stark_pub_key: felt252, deployment_params: Span<felt252>
    );
    fn get_mock_params(self: @TState) -> (felt252, MockDeploymentParams);
}

#[starknet::contract(account)]
pub mod MockAccount {
    use core::option::OptionTrait;
    use starknet::{AccountContract, account::Call};
    use super::{MockDeploymentParams, IMockFirstTimeInit};

    #[storage]
    struct Storage {
        mock_pub_key: felt252,
        params_after_init: MockDeploymentParams,
    }

    #[constructor]
    fn constructor(ref self: ContractState, mock_pub_key: felt252) {
        self.mock_pub_key.write(mock_pub_key);
    }

    #[abi(embed_v0)]
    impl InitMockImpl of IMockFirstTimeInit<ContractState> {
        fn initializer_from_factory(
            ref self: ContractState, stark_pub_key: felt252, mut deployment_params: Span<felt252>
        ) {
            self
                .params_after_init
                .write(Serde::<MockDeploymentParams>::deserialize(ref deployment_params).unwrap());
        }

        fn get_mock_params(self: @ContractState) -> (felt252, MockDeploymentParams) {
            (self.mock_pub_key.read(), self.params_after_init.read())
        }
    }

    #[abi(embed_v0)]
    impl AccountImpl of AccountContract<ContractState> {
        fn __validate_declare__(self: @ContractState, class_hash: felt252) -> felt252 {
            return 0;
        }

        fn __validate__(ref self: ContractState, calls: Array<Call>) -> felt252 {
            return 0;
        }

        fn __execute__(ref self: ContractState, calls: Array<Call>) -> Array<Span<felt252>> {
            return array![array![0].span()];
        }
    }
}
