// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.18;

import {FunctionsClient} from "@chainlink/contracts/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SportBet is
    FunctionsClient,
    ConfirmedOwner,
    AutomationCompatibleInterface
{
    using FunctionsRequest for FunctionsRequest.Request;
    using Strings for uint256;
    
    struct Game {
        uint256 id;
        uint256 bets;
        uint256 amount;
        uint256 winnerTeam;
        string title;
        uint256 startTime;
        uint256 endTime;
        bool isStarted;
        bool isEnded;
        string status;
    }

    struct Bet {
        uint256 gameId;
        uint256 team;
        address user;
    }

    mapping(uint256 => Bet[]) internal _bets;
    mapping(uint256 => Game) public _games;
    mapping(uint256 => address[]) internal _winners;
 

    uint256 internal _gameIdCounter;
    uint64 subscriptionId;
    uint256 public lastTime;
    uint256 intervalTime = 100; //5 minute

    // State variables to store the last request ID, response, and error 
    bytes32 public sLastRequestIdCreate;
    bytes32 public sLastRequestIdUpdate;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    event BitPlaced(uint256, address);

    // Router address - Hardcoded for Sepolia
    // Check to get the router address for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    address _router = 0xC22a79eBA640940ABB6dF0f7982cc119578E11De;

    // JavaScript source code
    string _source =
        "const { ethers } = await import('npm:ethers@6.12.1');"
        "const abiCoder = ethers.AbiCoder.defaultAbiCoder();"
        "const config = {"
        "url: 'https://decent-oddly-barnacle.ngrok-free.app/get_games',"
        "};"
        "const response = await Functions.makeHttpRequest(config);"
        "const tmpData = abiCoder.encode(['string title', 'uint256 amount', 'uint256 startTime'],"
        "    response.data);"
        "return ethers.getBytes(tmpData);";

    string _updateSource =
        "const { ethers } = await import('npm:ethers@6.12.1');"
        "const abiCoder = ethers.AbiCoder.defaultAbiCoder();"
        "const config = {"
        "url: `https://decent-oddly-barnacle.ngrok-free.app/update_games?gameId=${args[0]}`,"
        "};"
        "const response = await Functions.makeHttpRequest(config);"
        "const tmpData = abiCoder.encode(['string status', 'uint256 gameId', 'uint256 endTime'],"
        "    response.data);"
        "return ethers.getBytes(tmpData);";

    //Callback gas limit
    uint32 _gasLimit = 300000;

    // donID - Hardcoded for Sepolia
    // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    bytes32 _donID =
        0x66756e2d706f6c79676f6e2d616d6f792d310000000000000000000000000000;

    constructor( 
        uint64 _subscriptionId
    ) FunctionsClient(_router) ConfirmedOwner(msg.sender) { 
        subscriptionId = _subscriptionId;
    }

    function getBetPrice(uint256 gameId) external view returns (uint256) {
        return _games[gameId].amount;
    }

    function getGames() external view returns (Game[] memory) {
        Game[] memory gameArray = new Game[](_gameIdCounter); // Initialize the memory array with the correct size
        for (uint256 index = 0; index < _gameIdCounter; index++) {
            gameArray[index] = _games[index + 1];
        }
        return gameArray;
    }

    function getWinners(
        uint256 gameId
    ) external view returns (address[] memory) {
        return _winners[gameId];
    }

    function placeBet(Bet calldata bet) external payable {
        require(_games[bet.gameId].amount != 0, "SportBet: Invalid game");
        require(
            _games[bet.gameId].amount <= msg.value,
            "SportBet: Invalid bet amount"
        );
        require(bet.team < 2, "SportBet: Invalid team");
        _bets[bet.gameId].push(bet);
        _games[bet.gameId].bets = _games[bet.gameId].bets + 1;
        emit BitPlaced(bet.gameId, msg.sender);
    }

    function _settleGame(uint256 gameId) internal {
        uint256 finalAmount = 0;
        Game memory game = _games[gameId];
        Bet[] memory _tmpBets = new Bet[](_bets[gameId].length);
        uint256 winners = 0;
        for (uint256 index = 0; index < _bets[gameId].length; index++) {
            Bet memory element = _bets[gameId][index];
            finalAmount += game.amount;
            if (game.winnerTeam == element.team) {
                _tmpBets[index] = element;
                winners++;
            }
        }

        for (uint256 index = 0; index < _tmpBets.length; index++) {
            address payable receiver = payable(_tmpBets[index].user);
            receiver.transfer(finalAmount);
        }
        _games[gameId].isEnded = true;
        _games[gameId].status = "settled";
    }

    function createGame() external onlyOwner {
        sendRequestCreateGame();
    }

    function updateGame(uint256 gameId) internal {
        sendRequestUpdateGame(gameId);
    }

    function sendRequestCreateGame() internal {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(_source); // Initialize the request with JS code
        // Send the request and store the request ID
        sLastRequestIdCreate = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            _gasLimit,
            _donID
        );
    }

    function sendRequestUpdateGame(uint256 gameId) internal {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(_updateSource); // Initialize the request with JS code
        string[] memory args = new string[](1);
        args[0] = gameId.toString();
        req.setArgs(args);
        // Send the request and store the request ID
        sLastRequestIdUpdate = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            _gasLimit,
            _donID
        );
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (sLastRequestIdCreate == requestId) {
            // Create new game
            (string memory title, uint256 amount, uint256 startTime) = abi
                .decode(response, (string, uint256, uint256));
            _gameIdCounter++;
            Game memory gameData = Game(
                _gameIdCounter,
                0,
                amount,
                0,
                title,
                startTime,
                0,
                false,
                false,
                "created"
            );
            _games[_gameIdCounter] = gameData;
        } else if (sLastRequestIdUpdate == requestId) {
            // Update existing game
            (string memory gameStatus, uint256 gameId, uint256 endTime) = abi
                .decode(response, (string, uint256, uint256));
            if(!_games[gameId].isEnded){
                _games[gameId].isStarted = true; 
                _games[gameId].status = gameStatus;
                _games[gameId].endTime = endTime;
            }
        } else {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
    }

    function checkUpkeep(
        bytes calldata /*checkData*/
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if ((block.timestamp - lastTime) < intervalTime) {
            return (false, performData);
        }
        uint256[] memory gameIds = new uint256[](_gameIdCounter);
        uint256[] memory endGameIds = new uint256[](_gameIdCounter);
        uint256 indexCounter = 0;
        upkeepNeeded = false;
        for (uint256 index = 0; index < _gameIdCounter; index++) {
            // here is the game start code
            Game memory game = _games[index + 1];
            if (!game.isStarted && block.timestamp >= game.startTime) {
                gameIds[indexCounter] = game.id;
                indexCounter++;
                upkeepNeeded = true;
            }
        }
        indexCounter = 0;
        for (uint256 index = 0; index < _gameIdCounter; index++) {
            // here is the game end code
            Game memory game = _games[index + 1];
            if (
                game.isStarted &&
                !game.isEnded &&
                block.timestamp >= game.endTime
            ) {
                endGameIds[indexCounter] = game.id;
                indexCounter++;
                upkeepNeeded = true;
            }
        }
        performData = abi.encode(gameIds, endGameIds);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override {
        if ((block.timestamp - lastTime) > intervalTime) {
            lastTime = block.timestamp;
            (uint256[] memory gameIds, uint256[] memory endGameIds) = abi
                .decode(performData, (uint256[], uint256[]));
            for (uint256 index = 0; index < gameIds.length; index++) {
                updateGame(gameIds[index]);
            }
            for (uint256 index = 0; index < endGameIds.length; index++) {
                _settleGame(endGameIds[index]);
            }
        }
    }
}
