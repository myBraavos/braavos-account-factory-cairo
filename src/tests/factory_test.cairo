use core::serde::Serde;
use openzeppelin::access::ownable;
use openzeppelin::access::ownable::interface::IOwnableDispatcherTrait;
use openzeppelin::upgrades;
use openzeppelin::upgrades::interface::IUpgradeableDispatcherTrait;
use starknet::{
    get_contract_address, syscalls::deploy_syscall, ContractAddress, testing::set_contract_address,
};
use braavos_account_factory::factory::{
    Factory, IBraavosAccountFactoryDispatcher, IBraavosAccountFactoryDispatcherTrait,
};
use braavos_account_factory::tests::mocks::account_mock::IMockFirstTimeInitDispatcherTrait;
use braavos_account_factory::tests::mocks::account_mock::{
    MockAccount, MockDeploymentParams, IMockFirstTimeInitDispatcher
};

const ADMIN_ACCOUNT_ADDRESS: felt252 = 'admin_account';


fn setup() -> (IBraavosAccountFactoryDispatcher,) {
    let (address, _) = deploy_syscall(
        class_hash: Factory::TEST_CLASS_HASH.try_into().unwrap(),
        contract_address_salt: 0,
        calldata: array![].span(),
        deploy_from_zero: true
    )
        .expect('DEPLOY_FAILED');
    IBraavosAccountFactoryDispatcher { contract_address: address }
        .initializer(
            ADMIN_ACCOUNT_ADDRESS.try_into().unwrap(),
            MockAccount::TEST_CLASS_HASH.try_into().unwrap()
        );
    return (IBraavosAccountFactoryDispatcher { contract_address: address },);
}

#[test]
fn test_initialization() {
    let (factory_dispatch,) = setup();
    assert(
        ownable::interface::IOwnableDispatcher {
            contract_address: factory_dispatch.contract_address
        }
            .owner() == ADMIN_ACCOUNT_ADDRESS
            .try_into()
            .unwrap(),
        'INIT_FAILED'
    );
    assert(
        factory_dispatch.get_base_class_hash() == MockAccount::TEST_CLASS_HASH.try_into().unwrap(),
        'INIT_FAILED'
    );
}

#[test]
fn test_upgrade() {
    let (factory_dispatch,) = setup();
    set_contract_address(ADMIN_ACCOUNT_ADDRESS.try_into().unwrap());
    upgrades::interface::IUpgradeableDispatcher {
        contract_address: factory_dispatch.contract_address
    }
        .upgrade(Factory::TEST_CLASS_HASH.try_into().unwrap());
}


#[test]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', 'ENTRYPOINT_FAILED'))]
fn test_upgrade_fail_not_factory() {
    let (factory_dispatch,) = setup();
    set_contract_address(ADMIN_ACCOUNT_ADDRESS.try_into().unwrap());
    upgrades::interface::IUpgradeableDispatcher {
        contract_address: factory_dispatch.contract_address
    }
        .upgrade(MockAccount::TEST_CLASS_HASH.try_into().unwrap());
}


#[test]
#[should_panic(expected: ('Caller is not the owner', 'ENTRYPOINT_FAILED'))]
fn test_upgrade_fail_not_owner() {
    let (factory_dispatch,) = setup();
    set_contract_address('dummy'.try_into().unwrap());
    upgrades::interface::IUpgradeableDispatcher {
        contract_address: factory_dispatch.contract_address
    }
        .upgrade(0.try_into().unwrap());
}

#[test]
fn test_deployment_from_factory() {
    let (factory_dispatch,) = setup();
    let dummy_stark_pubk = 0x12341234;
    let mut mock_depl_params_serlz = array![];

    let mock_depl_params = MockDeploymentParams {
        class_hash: MockAccount::TEST_CLASS_HASH.try_into().unwrap(),
        mock1: 'mock1',
        mock2: 'mock2',
        mock3: ('mock3.1', 'mock3.2'),
    };
    mock_depl_params.serialize(ref mock_depl_params_serlz);
    let account_address = factory_dispatch
        .deploy_braavos_account(dummy_stark_pubk, mock_depl_params_serlz.span(),);
    assert(
        IMockFirstTimeInitDispatcher { contract_address: account_address }
            .get_mock_params() == (dummy_stark_pubk, mock_depl_params),
        'INVALID_INIT_DEPL_PARAMS'
    );
}
