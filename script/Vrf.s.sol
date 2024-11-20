// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Vrf} from "../src/VRF.sol";
import {IDepositUserContract} from "../src/Interfaces/IDepositUserContract.sol";

contract VrfScript is Script {
    function setUp() public {}

    function run() public {
        address supraDeposit = 0x3010eD244167EAD55Fee447bA83B15DD5AF37258;
        address supraAddress = 0xa7180E30a93AD77D97922608E1af5751Ec156e8A;
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        Vrf vrf = new Vrf(supraAddress);
        IDepositUserContract depositUserContract = IDepositUserContract(
            supraDeposit
        );
        depositUserContract.addContractToWhitelist(address(vrf));
        vm.stopBroadcast();
    }
}
