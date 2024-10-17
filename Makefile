-include .env

deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) --account sepoliaKey --sender 0xf5143cF478266d852565759D81D768a25dEa7225 --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv 