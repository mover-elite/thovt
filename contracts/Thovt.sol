// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ThovtToken is ERC20, Ownable {
    uint256 public treasuryTaxRate = 3; // 3%
    uint256 public dividendTaxRate = 1; // 1%
    uint256 public operationsTaxRate = 1; // 1%

    address public treasuryAddress;
    address public operationsAddress;
    address[] private _holders;

    mapping(address => bool) private _isExcludedFromTax;



    event TaxRatesUpdated(uint256 treasuryRate, uint256 dividendRate, uint256 operationsRate);
    event DistributeDivident(address indexed receiver, uint amount);
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address _treasuryAddress,
        address _operationsAddress
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _isExcludedFromTax[msg.sender] = true;
        _mint(msg.sender, initialSupply);
        treasuryAddress = _treasuryAddress;
        operationsAddress = _operationsAddress;
    }

    function setTaxRates(uint256 _treasuryRate, uint256 _dividendRate, uint256 _operationsRate) external onlyOwner {
        treasuryTaxRate = _treasuryRate;
        dividendTaxRate = _dividendRate;
        operationsTaxRate = _operationsRate;
        emit TaxRatesUpdated(_treasuryRate, _dividendRate, _operationsRate);
    }

    function transfer(address to, uint256 value) public override returns(bool) {
        address sender = msg.sender;
        uint256 totalTax = _isExcludedFromTax[to] ? 0 :  treasuryTaxRate + dividendTaxRate + operationsTaxRate;
        uint256 taxAmount = (value * totalTax) / 100;
        uint256 amountAfterTax = value - taxAmount;

        _transfer(sender, to, amountAfterTax);
        
        

        if (taxAmount > 0) {
            uint256 treasuryAmount = (taxAmount * treasuryTaxRate) / totalTax;
            uint256 dividendAmount = (taxAmount * dividendTaxRate) / totalTax;
            uint256 operationsAmount = (taxAmount * operationsTaxRate) / totalTax;
            if (treasuryAmount > 0) _transfer(sender, treasuryAddress, treasuryAmount);
            if (operationsAmount > 0) _transfer(sender, operationsAddress, operationsAmount);
            if(dividendAmount > 0) distributeDivident(dividendAmount);
        }
        if (balanceOf(sender) == 0) {
            _removeHolder(sender);
        }

        _addHolder(to);
        return true;

    }
    function distributeDivident(uint amount) internal {
        uint256 numHolders = _holders.length;
        
        if(numHolders == 0){
            return;
        }

        uint256 amountPerHolder = amount / numHolders;
        if(amountPerHolder  == 0 ) {
            return; 
        }

        for (uint256 i = 0; i < numHolders; i++) {
            _transfer(msg.sender, _holders[i], amountPerHolder);
            emit DistributeDivident(_holders[i], amountPerHolder);
        }
    }


     function _addHolder(address holder) private {
        if (balanceOf(holder) > 0) {
            _holders.push(holder);
        }
    }

    
    function _removeHolder(address holder) private {
        for (uint256 i = 0; i < _holders.length; i++) {
            if (_holders[i] == holder) {
                _holders[i] = _holders[_holders.length - 1];
                _holders.pop();
                break;
            }
        }
    }

    function toggleisExcludedFromTax (address addr, bool state) external onlyOwner() {
        _isExcludedFromTax[addr] = state;
    }

    function isExcludedFromTax (address addr) external view returns(bool) {
        return _isExcludedFromTax[addr];
    }

     function isHolder(address account) public view returns (bool) {
        for (uint256 i = 0; i < _holders.length; i++) {
            if (_holders[i] == account) {
                return true;
            }
        }
        return false;
    }

    function totalHolders() external view returns(uint) {
        return _holders.length;
    }


}
