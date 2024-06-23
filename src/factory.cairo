use starknet::{ClassHash, ContractAddress};

#[starknet::interface]
pub trait IBraavosAccountFactory<TState> {
    fn initializer(ref self: TState, owner: ContractAddress, base_class_hash: ClassHash);
    fn braavos_account_factory_version(self: @TState) -> felt252;
    fn set_base_class_hash(ref self: TState, new_base_class_hash: ClassHash);
    fn get_base_class_hash(self: @TState) -> ClassHash;
    fn deploy_braavos_account(
        self: @TState, stark_pub_key: felt252, additional_deployment_params: Span<felt252>
    ) -> ContractAddress;
}


#[starknet::contract]
pub mod Factory {
    use core::num::traits::Zero;
    use core::option::OptionTrait;
    use core::serde::Serde;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::{
        interface::IUpgradeable, upgradeable::UpgradeableComponent::InternalTrait,
        UpgradeableComponent,
    };
    use starknet::{ClassHash, ContractAddress, syscalls, SyscallResultTrait};

    use braavos_account_factory::factory::{
        IBraavosAccountFactory, IBraavosAccountFactoryLibraryDispatcher,
        IBraavosAccountFactoryDispatcherTrait,
    };

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        initialized: bool,
        base_class_hash: ClassHash,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    const BRAAVOS_ACCOUNT_FACTORY_INITIALIZER: felt252 = selector!("initializer_from_factory");

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl BraavosAccountFactoryImpl of IBraavosAccountFactory<ContractState> {
        fn braavos_account_factory_version(self: @ContractState) -> felt252 {
            return '001.000.000';
        }

        fn initializer(
            ref self: ContractState, owner: ContractAddress, base_class_hash: ClassHash
        ) {
            assert(self.initialized.read() == false, 'ALREADY_INITIALIZED');
            self.ownable.initializer(owner);
            self.base_class_hash.write(base_class_hash);
            self.initialized.write(true);
        }

        fn set_base_class_hash(ref self: ContractState, new_base_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.base_class_hash.write(new_base_class_hash);
        }

        fn get_base_class_hash(self: @ContractState) -> ClassHash {
            self.base_class_hash.read()
        }

        fn deploy_braavos_account(
            self: @ContractState,
            stark_pub_key: felt252,
            additional_deployment_params: Span<felt252>
        ) -> ContractAddress {
            let base_chash = self.base_class_hash.read();
            assert(!base_chash.is_zero(), 'NOT_INITIALIZED');
            let (address, _) = syscalls::deploy_syscall(
                class_hash: self.base_class_hash.read(),
                contract_address_salt: stark_pub_key,
                calldata: array![stark_pub_key].span(),
                deploy_from_zero: true
            )
                .unwrap_syscall();

            let mut init_cdata = array![stark_pub_key];
            init_cdata.append(additional_deployment_params.len().into());
            init_cdata.append_span(additional_deployment_params);
            syscalls::call_contract_syscall(
                address: address,
                entry_point_selector: BRAAVOS_ACCOUNT_FACTORY_INITIALIZER,
                calldata: init_cdata.span(),
            )
                .unwrap_syscall();

            return address;
        }
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            // (Soft) guarantee that we are upgrading to a Braavos Account Factory to avoid
            // mistakes. The below line will panic if new_class_hash does not implement the
            // get version api
            IBraavosAccountFactoryLibraryDispatcher { class_hash: new_class_hash }
                .braavos_account_factory_version();
            self.upgradeable._upgrade(new_class_hash);
        }
    }
}
