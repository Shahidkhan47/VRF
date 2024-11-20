// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Vrf} from "../src/VRF.sol";
import {MockRandom} from "../src/MockRandom.sol";

contract VrfTest is Test {
    Vrf public vrf;
    MockRandom public mockrandom;

    address public owner = address(11111);
    address public participant1 = address(22222);
    address public participant2 = address(33333);
    address public participant3 = address(44444);
    address public participant4 = address(55555);
    address public participant5 = address(66666);
    address public participant6 = address(77777);

    function setUp() public {
        vm.startPrank(owner);
        mockrandom = new MockRandom();
        vrf = new Vrf(address(mockrandom));
        mockrandom.setAddress(address(vrf));
        vm.stopPrank();
    }

    function creategameTest(
        address _owner,
        uint _gameNum,
        string memory _text
    ) public returns (bytes32) {
        vm.startPrank(_owner);
        bytes32 _gameId = vrf.creategame(_gameNum, _text);
        vm.stopPrank();
        return _gameId;
    }

    function addparticipate(
        address _participant,
        bytes32 _gameId,
        uint _choice
    ) public {
        vm.startPrank(_participant);
        vm.deal(_participant, 1 ether);
        vrf.participate{value: 0.1 ether}(_gameId, _choice);
        vm.stopPrank();
    }

    function testFail_creategame_Owner() public {
        creategameTest(participant1, 1, "game1");
    }

    function testParticipate() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 2);
        addparticipate(participant2, _gameId, 4);
        addparticipate(participant3, _gameId, 6);
        addparticipate(participant4, _gameId, 8);
        addparticipate(participant5, _gameId, 10);
        assertEq(address(vrf).balance, 0.5 ether);
    }

    function testFail_participate_choice() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 33);
    }

    function testFail_participateAgain() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 2);
        addparticipate(participant1, _gameId, 2);
    }

    function testFail_participate_limit() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 12);
        addparticipate(participant2, _gameId, 2);
        addparticipate(participant3, _gameId, 4);
        addparticipate(participant4, _gameId, 6);
        addparticipate(participant5, _gameId, 8);
        addparticipate(participant6, _gameId, 10);
    }

    function test_spin() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 12);
        addparticipate(participant2, _gameId, 2);
        addparticipate(participant3, _gameId, 4);
        addparticipate(participant4, _gameId, 6);
        addparticipate(participant5, _gameId, 8);
        vm.prank(owner);
        vrf.spin(_gameId);
    }
    function testFail_spinFailed_owner() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 12);
        addparticipate(participant2, _gameId, 2);
        addparticipate(participant3, _gameId, 4);
        vm.prank(participant1);
        vrf.spin(_gameId);
    }

    function testFail_spinFailed_limit() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 12);
        addparticipate(participant2, _gameId, 2);
        vm.prank(owner);
        vrf.spin(_gameId);
    }
    
     function testFail_afterSpinned() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 12);
        addparticipate(participant2, _gameId, 2);
        addparticipate(participant3, _gameId, 10);
        addparticipate(participant4, _gameId, 6);
        vm.prank(owner);
        vrf.spin(_gameId);
        addparticipate(participant5, _gameId, 16);
    }
    
    function testFinalize_Nomatch() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 12);
        addparticipate(participant2, _gameId, 2);
        addparticipate(participant3, _gameId, 4);
        addparticipate(participant4, _gameId, 6);
        addparticipate(participant5, _gameId, 8);
        assertEq(address(vrf).balance, 0.5 ether);
        uint prevBalance = address(participant1).balance;
        uint divide = (250000000000000000 / 5);
        console.log("prevBalance", prevBalance);
        vm.startPrank(owner);
        vrf.spin(_gameId);
        mockrandom.declare();
        vrf.finalize(_gameId);
        assertEq(address(vrf).balance, 0.25 ether);
        assertEq(address(participant1).balance, (prevBalance + divide));
        vm.stopPrank();
    }

    function testFinalize_match() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 12);
        addparticipate(participant2, _gameId, 2);
        addparticipate(participant3, _gameId, 10);
        addparticipate(participant4, _gameId, 6);
        addparticipate(participant5, _gameId, 10);
        assertEq(address(vrf).balance, 0.5 ether);
        uint prevBalanceWinner = address(participant3).balance;
        uint prevBalanceOther = address(participant1).balance;
        vm.startPrank(owner);
        vrf.spin(_gameId);
        mockrandom.declare();
        vrf.finalize(_gameId);
        assertEq(address(vrf).balance, 0.25 ether);
        assertEq(
            address(participant3).balance,
            (prevBalanceWinner + 0.25 ether)
        );
        assertEq(address(participant1).balance, prevBalanceOther);
        vm.stopPrank();
    }

    function testFail_finalize() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 12);
        addparticipate(participant2, _gameId, 2);
        addparticipate(participant3, _gameId, 10);
        addparticipate(participant4, _gameId, 6);
        addparticipate(participant5, _gameId, 14);
        vm.prank(owner);
        vrf.finalize(_gameId);
    }

    function testFail_finalize_owner() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 12);
        addparticipate(participant2, _gameId, 2);
        addparticipate(participant3, _gameId, 10);
        addparticipate(participant4, _gameId, 6);
        addparticipate(participant5, _gameId, 16);
        vm.prank(owner);
        vrf.spin(_gameId);
        vm.prank(participant1);
        vrf.finalize(_gameId);
    }

    function testFail_afterFinalized1() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 12);
        addparticipate(participant2, _gameId, 2);
        addparticipate(participant3, _gameId, 10);
        addparticipate(participant4, _gameId, 6);
        vm.startPrank(owner);
        vrf.spin(_gameId);
        vrf.finalize(_gameId);
        vm.stopPrank();
        addparticipate(participant5, _gameId, 16);
    }

    function testFail_afterFinalized2() public {
        bytes32 _gameId = creategameTest(owner, 1, "game1");
        addparticipate(participant1, _gameId, 12);
        addparticipate(participant2, _gameId, 2);
        addparticipate(participant3, _gameId, 10);
        addparticipate(participant4, _gameId, 6);
        addparticipate(participant5, _gameId, 16);
        vm.startPrank(owner);
        vrf.spin(_gameId);
        vrf.finalize(_gameId);
        vrf.spin(_gameId);
        vm.stopPrank();

    }
}
