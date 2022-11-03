


const contract = await NftMarket.deployed()

contract.mintToken("https://gateway.pinata.cloud/ipfs/QmbiE5ZdZb97C7WuCmbSQ6o7yHn4FRroojwmGDLtevPHC7", "500000000000000000", {value: 25000000000000000,from: accounts[0]})
contract.mintToken("https://gateway.pinata.cloud/ipfs/QmbTp4n88Yjj931Gg4qz4LYLuCSdQwCv6sn5u8fzs16KsB", "500000000000000000", {value: 25000000000000000,from: accounts[0]})