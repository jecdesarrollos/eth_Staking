/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC-20 custom token IJERC-20 Interface
 * @notice this implements an JERC-20 token.
 * @author ~ Jorge Enrique Cabrera Curso Ashitaka ETH KIPU 2024
 */

interface IJERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value); 

    /**
     * @dev Returns the total amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
      * Returns a ~ success boolean value
      * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. 
     * default: 0
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


contract MyToken is IJERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    /**
     * @notice Constructs the token with a name and symbol
     * @param name_ token name
     * @param symbol_ token symbol
     */
constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
    _mint(msg.sender, 1000000 * 10 ** 18);
}

    /** 
     * @notice Returns token name
     * @return token name
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns token symbol
     * @return token symbol
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @return decimals
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @return total supply of tokens
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns account balance of tokens
     * @param account account address
     * @return account balance of tokens
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Transfers tokens from the caller to another address.
     * @param to recipient address
     * @param amount tokens amount to transfer
     * @return A maybe successful ~ boolean value 
     * @dev _transfer emits a {Transfer} event
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @notice Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom} 
     * default 0
     * @param owner owner token address
     * @param spender spender address
     * @return remaining allowance
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     * @param spender spender address
     * @param amount tokens amount to allow.
     * @return A ~ succesful boolean value
     * @dev _approve emits the {Approval} event
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @notice Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance
     * @param from msg sender address
     * @param to recipient address
     * @param amount tokens amount to transfer
     * @return A ~succesful boolean value
     * @dev _transfer emits a {Transfer} event
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Transfers `amount` tokens from `from` to `to`.
     * @param from msg sender address
     * @param to recipient address
     * @param amount tokens amount to transfer
     * @dev This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     * @dev Emits a {Transfer} event
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "Transfer from address 0");
        require(to != address(0), "Transfer to address 0");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Balance exceeded");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    /**
     * @notice Transfers `amount` tokens from `from` to `to`.
     * @param recipients addresses array
     * @param amount tokens amount to distribute
     * @dev mint tokens _mint emits Transfer event
    */   
    function distributeTokens(address[] memory recipients, uint256 amount) public {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amount);
        }
    }

    /** @notice Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * @param account recipient address
     * @param amount tokens amount to create
     * @dev Emits a {Transfer} event with `from` set to the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "mint to the 0 address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * @param owner The address of the token owner.
     * @param spender The address of the spender.
     * @param amount The amount of tokens to allow.
     * @dev Emits an {Approval} event.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "approve from the 0 address");
        require(spender != address(0), "approve to the 0 address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Updates `_allowances` during spending
     * @param owner token owner address
     * @param spender spender address
     * @param amount tokens amount to spend
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}