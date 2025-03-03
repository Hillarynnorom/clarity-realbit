import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that listing creation works with expiry",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const expiry = chain.blockHeight + 100;
    
    let block = chain.mineBlock([
      Tx.contractCall("market", "create-listing", [
        types.principal(deployer.address),
        types.uint(100),
        types.uint(1000),
        types.uint(expiry)
      ], deployer.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
  },
});

Clarinet.test({
  name: "Ensure partial share purchase works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const buyer = accounts.get("wallet_1")!;
    const expiry = chain.blockHeight + 100;
    
    let block = chain.mineBlock([
      Tx.contractCall("market", "create-listing", [
        types.principal(deployer.address),
        types.uint(100),
        types.uint(1000),
        types.uint(expiry)
      ], deployer.address),
      Tx.contractCall("market", "purchase-shares", [
        types.uint(1),
        types.uint(50)
      ], buyer.address)
    ]);
    
    assertEquals(block.receipts.length, 2);
    block.receipts[1].result.expectOk().expectBool(true);
  },
});
