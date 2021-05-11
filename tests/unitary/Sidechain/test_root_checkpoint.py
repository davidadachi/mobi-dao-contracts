import pytest

WEEK = 7 * 86400


@pytest.mark.skip_coverage
def test_relative_weight_write(accounts, chain, gauge_controller, liquidity_gauge, root_gauge, token, minter):
    token.set_minter(minter, {'from': accounts[0]})
    chain.mine(timedelta=WEEK)
    token.update_mining_parameters({'from': accounts[0]})

    gauge_controller.add_type("Test", 10**18, {'from': accounts[0]})
    gauge_controller.add_gauge(liquidity_gauge, 0, 0, {"from": accounts[0]})
    gauge_controller.add_gauge(root_gauge, 0, 1, {"from": accounts[0]})

    chain.mine(timedelta=WEEK)

    rate = token.rate()
    total_emissions = 0
    assert rate > 0

    for i in range(1, 110):
        # 110 weeks ensures we see 2 reductions in the rate
        root_gauge.checkpoint()
        new_emissions = root_gauge.emissions() - total_emissions
        expected = rate * WEEK // i
        assert abs(new_emissions - expected) / expected < 0.0001

        total_emissions += new_emissions
        rate = token.rate()

        # increaseing the gauge weight on `liquidity_gauge` each week reducees
        # the expected emission for `root_gauge` in the following week
        gauge_controller.change_gauge_weight(liquidity_gauge, i, {'from': accounts[0]})
        chain.mine(timedelta=WEEK)
