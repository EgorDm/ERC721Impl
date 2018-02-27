import assertRevert from "./helpers/assertRevert";

require('truffle-test-utils').init();

const contractArtifact = artifacts.require('ERC721');

contract('TestERC721', function (accounts) {

    const NAME = 'FooBarCoin';
    const SYMBOL = 'FBC';

    const CONTRACT_OWNER = accounts[0];
    const TOKEN_OWNER_1 = accounts[1];
    const TOKEN_OWNER_2 = accounts[2];
    const TOKEN_OWNER_3 = accounts[3];

    const INITIAL_TOKEN_COUNT = 5;

    let ERC721;

    async function deployContract() {
        ERC721 = await contractArtifact.new(NAME, SYMBOL, {from: CONTRACT_OWNER});
    }

    async function createTokens(count, address = null) {
        for (let i = 0; i < count; i++) {
            if (!address) await ERC721.createToken(i);
            else await ERC721.createTokenFor(`${address}`, i);
        }
    }

    async function deployContractWithTokens() {
        await deployContract();
        await createTokens(INITIAL_TOKEN_COUNT, CONTRACT_OWNER);
        await createTokens(INITIAL_TOKEN_COUNT, TOKEN_OWNER_1);
        await createTokens(INITIAL_TOKEN_COUNT, TOKEN_OWNER_2);
        await createTokens(INITIAL_TOKEN_COUNT, TOKEN_OWNER_3);
    }

    describe("Init", function () {
        before(deployContract);

        it('name and symbol should match', async () => {
            const name = await ERC721.name();
            const symbol = await ERC721.symbol();
            assert.strictEqual(name, NAME);
            assert.strictEqual(symbol, SYMBOL);
        });
    });

    describe("totalSupply", function () {
        beforeEach(deployContract);

        it('totalSupply should return 0 for initial supply.', async () => {
            const supply = await ERC721.totalSupply();
            assert.strictEqual(supply.toNumber(), 0);
        });

        it('should return correct supply after each token creation', async () => {
            for (let i = 0; i < 5; ++i) {
                await ERC721.createToken(i);
                const supply = await ERC721.totalSupply();
                assert.strictEqual(supply.toNumber(), i + 1);
            }
        });
    });

    describe("balanceOf & createTokens", function () {
        before(deployContract);

        it('should be able to create tokens for the owner and return correct balance', async () => {
            await createTokens(INITIAL_TOKEN_COUNT);

            const balance = await ERC721.balanceOf(`${CONTRACT_OWNER}`);
            assert.strictEqual(balance.toNumber(), INITIAL_TOKEN_COUNT);
        });

        it('should be able to create tokens for a specific address and return correct balance', async () => {
            await createTokens(INITIAL_TOKEN_COUNT, TOKEN_OWNER_1);

            const balance = await ERC721.balanceOf(`${TOKEN_OWNER_1}`);
            assert.strictEqual(balance.toNumber(), INITIAL_TOKEN_COUNT);
        });
    });

    describe("tokensOf", function () {
        before(deployContractWithTokens);

        it('Should contain all the token ids user owns', async () => {
            const tokens = await ERC721.tokensOf(`${CONTRACT_OWNER}`);
            for(let i = 0; i < tokens.length; i++) {
                assert.strictEqual(tokens[i].toNumber(), i);
            }
        });
    });

    describe("ownerOf", function () {
        before(deployContractWithTokens);

        it("Should return correct owner of a token", async () => {
            assert.strictEqual(await ERC721.ownerOf(`${0}`), CONTRACT_OWNER);
            assert.strictEqual(await ERC721.ownerOf(`${INITIAL_TOKEN_COUNT}`), TOKEN_OWNER_1);
            assert.strictEqual(await ERC721.ownerOf(`${INITIAL_TOKEN_COUNT * 2}`), TOKEN_OWNER_2);
            assert.strictEqual(await ERC721.ownerOf(`${INITIAL_TOKEN_COUNT * 3}`), TOKEN_OWNER_3);
        });

        it("Should throw exception when non existing coin is specified", async () => {
            await assertRevert(ERC721.ownerOf(`${999}`));
        });
    });

    describe("changeOwnership", function () {
        before(deployContractWithTokens);

        it("User cannot claim token without approval", async () => {
            await assertRevert(ERC721.takeOwnership(`${0}`));
        });

        it("User cannot approve transaction if he is not the owner", async () => {
            await assertRevert(ERC721.approve(`${TOKEN_OWNER_1}`, `${0}`, {from: TOKEN_OWNER_3}));
        });

        it("Owner can give approval to another address", async () => {
            let result = await ERC721.approve(`${TOKEN_OWNER_1}`, `${0}`);
            assert.web3Event(result, {
                event: 'Approval',
                args: {
                    owner: CONTRACT_OWNER,
                    approved: TOKEN_OWNER_1,
                    tokenId: 0
                }
            }, 'The event is emitted');
        });

        it("Approved user can claim his token", async () => {
            let result = await ERC721.takeOwnership(`${0}`, {from: TOKEN_OWNER_1});
            assert.web3Event(result, {
                event: 'Transfer',
                args: {
                    from: CONTRACT_OWNER,
                    to: TOKEN_OWNER_1,
                    tokenId: 0
                }
            }, 'The event is emitted');
        });

        it("Ownership of the token has changed", async () => {
            assert.strictEqual(await ERC721.ownerOf(`${0}`), TOKEN_OWNER_1);
        });

        it("Token cannot be reclaimed by previous owner", async () => {
            await assertRevert(ERC721.takeOwnership(`${0}`));
        });
    });

    describe("transfer", function () {
        before(deployContractWithTokens);

        it("User cannot transfer token without approval", async () => {
            await assertRevert(ERC721.transfer(`${TOKEN_OWNER_1}`, `${0}`, {from: TOKEN_OWNER_3}));
        });

        it("Owner cannot transfer a token to himself", async () => {
            await assertRevert(ERC721.transfer(`${CONTRACT_OWNER}`, `${0}`));
        });

        it("Owner can transfer a token to another address", async () => {
            let result = await ERC721.transfer(`${TOKEN_OWNER_1}`, `${0}`);
            assert.web3Event(result, {
                event: 'Transfer',
                args: {
                    from: CONTRACT_OWNER,
                    to: TOKEN_OWNER_1,
                    tokenId: 0
                }
            }, 'The event is emitted');
        });

        it("Ownership of the token has changed", async () => {
            assert.strictEqual(await ERC721.ownerOf(`${0}`), TOKEN_OWNER_1);
        });

        it("Token cannot be retransfered by previous owner", async () => {
            await assertRevert(ERC721.transfer(`${TOKEN_OWNER_3}`, `${0}`));
        });

        it("Approved user can transfer a token", async () => {
            ERC721.approve(`${CONTRACT_OWNER}`, `${0}`, {from: TOKEN_OWNER_1});
            assert.strictEqual(await ERC721.isApproved(`${CONTRACT_OWNER}`, `${0}`), true);

            let result = await ERC721.transfer(`${TOKEN_OWNER_3}`, `${0}`);
            assert.web3Event(result, {
                event: 'Transfer',
                args: {
                    from: TOKEN_OWNER_1,
                    to: TOKEN_OWNER_3,
                    tokenId: 0
                }
            }, 'The event is emitted');
        });
    });
});
