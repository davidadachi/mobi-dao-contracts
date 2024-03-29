# @version 0.2.7
"""
@title Mobius StableSwap Proxy
@author Mobius Finance
@license MIT
"""

interface Burner:
    def burn(_coin: address) -> bool: payable

interface Mobius:
    def withdrawAdminFees(): nonpayable
    def pause(): nonpayable
    def unpause(): nonpayable
    def transferOwnership(newOwner: address): nonpayable
    def renounceOwnership(): nonpayable
    def setAdminFee(newAdminFee: uint256): nonpayable
    def setSwapFee(newSwapFee: uint256): nonpayable
    def setDefaultDepositFee(newDepositFee: uint256): nonpayable
    def setDefaultWithdrawFee(newWithdrawFee: uint256): nonpayable
    def rampA(futureA: uint256, futureTime: uint256): nonpayable
    def stopRampA(): nonpayable
    def setDevAddress(_devaddr: address): nonpayable


MAX_COINS: constant(int128) = 8

struct PoolInfo:
    balances: uint256[MAX_COINS]
    underlying_balances: uint256[MAX_COINS]
    decimals: uint256[MAX_COINS]
    underlying_decimals: uint256[MAX_COINS]
    lp_token: address
    A: uint256
    fee: uint256

event CommitAdmins:
    ownership_admin: address
    emergency_admin: address

event ApplyAdmins:
    ownership_admin: address
    emergency_admin: address

event AddBurner:
    burner: address


ownership_admin: public(address)
emergency_admin: public(address)

future_ownership_admin: public(address)
future_emergency_admin: public(address)

min_asymmetries: public(HashMap[address, uint256])

burners: public(HashMap[address, address])
burner_kill: public(bool)

# pool -> caller -> can call `donate_admin_fees`
donate_approval: public(HashMap[address, HashMap[address, bool]])

@external
def __init__(
    _ownership_admin: address,
    _emergency_admin: address
):
    self.ownership_admin = _ownership_admin
    self.emergency_admin = _emergency_admin


@payable
@external
def __default__():
    # required to receive ETH fees
    pass


@external
def commit_set_admins(_o_admin: address, _e_admin: address):
    """
    @notice Set ownership admin to `_o_admin` and emergency admin to `_e_admin`
    @param _o_admin Ownership admin
    @param _e_admin Emergency admin
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    self.future_ownership_admin = _o_admin
    self.future_emergency_admin = _e_admin

    log CommitAdmins(_o_admin, _e_admin)


@external
def apply_set_admins():
    """
    @notice Apply the effects of `commit_set_admins`
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    _o_admin: address = self.future_ownership_admin
    _e_admin: address = self.future_emergency_admin
    self.ownership_admin = _o_admin
    self.emergency_admin = _e_admin

    log ApplyAdmins(_o_admin, _e_admin)


@internal
def _set_burner(_coin: address, _burner: address):
    old_burner: address = self.burners[_coin]
    if _coin != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
        if old_burner != ZERO_ADDRESS:
            # revoke approval on previous burner
            response: Bytes[32] = raw_call(
                _coin,
                concat(
                    method_id("approve(address,uint256)"),
                    convert(old_burner, bytes32),
                    convert(0, bytes32),
                ),
                max_outsize=32,
            )
            if len(response) != 0:
                assert convert(response, bool)

        if _burner != ZERO_ADDRESS:
            # infinite approval for current burner
            response: Bytes[32] = raw_call(
                _coin,
                concat(
                    method_id("approve(address,uint256)"),
                    convert(_burner, bytes32),
                    convert(MAX_UINT256, bytes32),
                ),
                max_outsize=32,
            )
            if len(response) != 0:
                assert convert(response, bool)

    self.burners[_coin] = _burner

    log AddBurner(_burner)


@external
@nonreentrant('lock')
def set_burner(_coin: address, _burner: address):
    """
    @notice Set burner of `_coin` to `_burner` address
    @param _coin Token address
    @param _burner Burner contract address
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    self._set_burner(_coin, _burner)


@external
@nonreentrant('lock')
def set_many_burners(_coins: address[20], _burners: address[20]):
    """
    @notice Set burner of `_coin` to `_burner` address
    @param _coins Token address
    @param _burners Burner contract address
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    for i in range(20):
        coin: address = _coins[i]
        if coin == ZERO_ADDRESS:
            break
        self._set_burner(coin, _burners[i])


@external
@nonreentrant('lock')
def withdraw_admin_fees(_pool: address):
    """
    @notice Withdraw admin fees from `_pool`
    @param _pool Pool address to withdraw admin fees from
    """
    Mobius(_pool).withdrawAdminFees()


@external
@nonreentrant('lock')
def withdraw_many(_pools: address[20]):
    """
    @notice Withdraw admin fees from multiple pools
    @param _pools List of pool address to withdraw admin fees from
    """
    for pool in _pools:
        if pool == ZERO_ADDRESS:
            break
        Mobius(pool).withdrawAdminFees()


@external
@nonreentrant('burn')
def burn(_coin: address):
    """
    @notice Burn accrued `_coin` via a preset burner
    @dev Only callable by an EOA to prevent flashloan exploits
    @param _coin Coin address
    """
    assert tx.origin == msg.sender
    assert not self.burner_kill

    _value: uint256 = 0
    if _coin == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
        _value = self.balance

    Burner(self.burners[_coin]).burn(_coin, value=_value)  # dev: should implement burn()


@external
@nonreentrant('burn')
def burn_many(_coins: address[20]):
    """
    @notice Burn accrued admin fees from multiple coins
    @dev Only callable by an EOA to prevent flashloan exploits
    @param _coins List of coin addresses
    """
    assert tx.origin == msg.sender
    assert not self.burner_kill

    for coin in _coins:
        if coin == ZERO_ADDRESS:
            break

        _value: uint256 = 0
        if coin == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
            _value = self.balance

        Burner(self.burners[coin]).burn(coin, value=_value)  # dev: should implement burn()


@external
@nonreentrant('lock')
def kill_me(_pool: address):
    """
    @notice Pause the pool `_pool` - only remove_liquidity will be callable
    @param _pool Pool address to pause
    """
    assert msg.sender == self.emergency_admin, "Access denied"
    Mobius(_pool).pause()


@external
@nonreentrant('lock')
def unkill_me(_pool: address):
    """
    @notice Unpause the pool `_pool`, re-enabling all functionality
    @param _pool Pool address to unpause
    """
    assert msg.sender == self.emergency_admin or msg.sender == self.ownership_admin, "Access denied"
    Mobius(_pool).unpause()


@external
def set_burner_kill(_is_killed: bool):
    """
    @notice Kill or unkill `burn` functionality
    @param _is_killed Burner kill status
    """
    assert msg.sender == self.emergency_admin or msg.sender == self.ownership_admin, "Access denied"
    self.burner_kill = _is_killed


@external
@nonreentrant('lock')
def transfer_ownership(_pool: address, new_owner: address):
    """
    @notice Transfer ownership for `_pool` pool to `new_owner` address
    @param _pool Pool which ownership is to be transferred
    @param new_owner New pool owner address
    """
    assert msg.sender == self.ownership_admin, "Access denied"
    Mobius(_pool).transferOwnership(new_owner)


@external
@nonreentrant('lock')
def renounce_ownership(_pool: address):
    """
    @notice Renounce ownership for `_pool`
    @param _pool Pool address
    """
    assert msg.sender == self.ownership_admin, "Access denied"
    Mobius(_pool).renounceOwnership()


@external
@nonreentrant('lock')
def set_admin_fee(_pool: address, new_admin_fee: uint256):
    """
    @notice Commit admin fee for `_pool` pool
    @param _pool Pool address
    @param new_admin_fee New admin fee
    """
    assert msg.sender == self.ownership_admin, "Access denied"
    Mobius(_pool).setAdminFee(new_admin_fee)

@external
@nonreentrant('lock')
def set_fee(_pool: address, new_fee: uint256):
    """
    @notice Commit fee for `_pool` pool
    @param _pool Pool address
    @param new_fee New fee
    """
    assert msg.sender == self.ownership_admin, "Access denied"
    Mobius(_pool).setSwapFee(new_fee)

@external
@nonreentrant('lock')
def set_deposit_fee(_pool: address, new_deposit_fee: uint256):
    """
    @notice Commit deposit fee for `_pool` pool
    @param _pool Pool address
    @param new_deposit_fee New deposit fee
    """
    assert msg.sender == self.ownership_admin, "Access denied"
    Mobius(_pool).setDefaultDepositFee(new_deposit_fee)


@external
@nonreentrant('lock')
def set_withdraw_fee(_pool: address, new_withdraw_fee: uint256):
    """
    @notice Commit withdraw fee for `_pool` pool
    @param _pool Pool address
    @param new_withdraw_fee New withdraw fee
    """
    assert msg.sender == self.ownership_admin, "Access denied"
    Mobius(_pool).setDefaultWithdrawFee(new_withdraw_fee)


@external
@nonreentrant('lock')
def ramp_A(_pool: address, _future_A: uint256, _future_time: uint256):
    """
    @notice Start gradually increasing A of `_pool` reaching `_future_A` at `_future_time` time
    @param _pool Pool address
    @param _future_A Future A
    @param _future_time Future time
    """
    assert msg.sender == self.ownership_admin, "Access denied"
    Mobius(_pool).rampA(_future_A, _future_time)


@external
@nonreentrant('lock')
def stop_ramp_A(_pool: address):
    """
    @notice Stop gradually increasing A of `_pool`
    @param _pool Pool address
    """
    assert msg.sender in [self.ownership_admin, self.emergency_admin], "Access denied"
    Mobius(_pool).stopRampA()


@external
@nonreentrant('lock')
def set_dev_addr(_pool: address, new_dev_addr: address):
    """
    @notice Set dev address for `_pool` pool to `new_dev_addr` address
    @param _pool Pool which ownership is to be transferred
    @param new_dev_addr New pool dev address
    """
    assert msg.sender == self.ownership_admin, "Access denied"
    Mobius(_pool).setDevAddress(new_dev_addr)
