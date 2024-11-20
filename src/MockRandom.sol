// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISupraRouterContract {
    function generateRequest(
        string memory _functionSig,
        uint8 _rngCount,
        uint256 _numConfirmations,
        address _clientWalletAddress
    ) external returns (uint256);
}
interface IVrf {
    function getnumber(uint256 _nonce, uint256[] memory _rngList) external;
    function aa(uint256 _nonce) external;
}
contract MockRandom is ISupraRouterContract {
    IVrf public vrf;

    uint256[] public numbers;

    function setAddress(address _Vrf) external {
        vrf = IVrf(_Vrf);
    }

    function generateRequest(
        string memory _functionSig,
        uint8 _rngCount,
        uint256 _numConfirmations,
        address _clientWalletAddress
    ) external override returns (uint256) {
        uint256 randomNum = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );
        numbers.push(randomNum);
        return (numbers.length);
    }

    function declare() external {
        vrf.getnumber(numbers.length, numbers);
    }
}
