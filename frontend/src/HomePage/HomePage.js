import { useState } from 'react';
import logo from '../logo.svg';
import viewIcon from '../view.png';
import './HomePage.css';
import { useNavigate } from 'react-router-dom';
import { Web3 } from "web3";
import contractAbi from "../abi/game.json";
import Modal from '../Modal/Modal';


function HomePage() {
    const CONTRACT_ADDRESS = "0x34614DA7b96E3896Fa6347f56ddf1a549EA16f0a";
    const [games, setGames] = useState();
    const [globalWeb3, setGlobalWeb3] = useState(null);
    const [showModal, setShowModal] = useState(false);
    const [teams, setTeams] = useState(null);
    const [wallet, setWallet] = useState(null);

    const handleShowModal = (_teams) => {
        setTeams(_teams);
        setShowModal(true);
    };

    const handleCloseModal = () => {
        setShowModal(false);
    };

    const handleBetInit = async (game, selected) => {
        try {
            const contractInstance = new globalWeb3.eth.Contract(contractAbi.abi, CONTRACT_ADDRESS);
            const result = await contractInstance.methods.placeBet([Number(game.id), Number(selected), wallet]).send({ from: wallet, value: game.amount });
            console.log(`SUCCESS : ${result.transactionHash}`);
        } catch (error) {
            console.log(error);
        }
    };

    const initWeb3 = async () => {
        // Check if MetaMask is installed
        if (window.ethereum) {
            return new Web3(window.ethereum);
        } else if (window.web3) {
            // Legacy dapp browsers...
            return new Web3(window.web3.currentProvider);
        }
    };

    const getGames = async () => {
        const web3 = await initWeb3();
        setGlobalWeb3(web3); 

        const contractInstance = new web3.eth.Contract(contractAbi.abi, CONTRACT_ADDRESS);
        try { 
            const response = await contractInstance.methods.getGames().call({ from: wallet });
            setGames(response);
        } catch (error) {
            console.error('Error calling contract function', error);
        }
    }

    const connectWallet = async () => {
        if (window.ethereum) {
            try {
                await handleChangeNetwork();
                // Request account access if needed
                const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
                console.log(accounts);
                setWallet(accounts[0]);
                getGames();
                // You can now interact with the user's MetaMask account
            } catch (error) {
                console.error('Error connecting wallet:', error);
            }
        } else {
            console.error('MetaMask is not installed');
        }
    };

    const handleChangeNetwork = async () => {
        if (window.ethereum) {
            try {
                // Prompt the user to change the network
                await window.ethereum.request({
                    method: 'wallet_switchEthereumChain',
                    params: [{ chainId: '0x13882' }] // Sepolia chain ID
                });
            } catch (error) {
                console.error('Error changing network:', error);
            }
        } else {
            console.error('MetaMask is not installed');
        }
    };

    const getConvertedAmount = (amount) => {
        return globalWeb3.utils.fromWei(amount, 'ether');
    }

    const getTableData = () => {
        return <table className='table_data'>
            <thead>
                <tr>
                    <th>Game Id</th>
                    <th>Game Title</th> 
                    <th>Bets</th>
                    <th>Crypto Required</th>
                    <th>status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                {games != undefined && games.map((val, key) => (
                    <tr key={key}>
                        <td><p className="list-item-data">{Number(val.id)}</p></td>
                        <td><p className="list-item-data">{val.title.split("vs")[0]} <br />V/S <br />{val.title.split("vs")[1]}</p></td> 
                        <td><p className="list-item-data ">{Number(val.bets)}/2</p></td>
                        <td><p className="list-item-data">{getConvertedAmount(val.amount)} ETH</p></td>
                        <td><p className="list-item-data">{val.status}</p></td>
                        <td>
                            <div className="connect-wallet-button">
                                <button onClick={() => handleShowModal(val)}>Chose</button>
                            </div>
                        </td>
                    </tr>
                ))}
            </tbody>
        </table>
    }

    const handleItemClick = (gameId) => {
        // Navigate to the details screen
        // navigate(`/details/${gameId}`); // Adjust the route as needed
    };

    return (
        <div className="HomePage">
            <div className="HomePage-header">
                <header>
                    <div className="connect-wallet-button">
                        <button onClick={connectWallet}>Connect Wallet</button>
                    </div>
                </header>
            </div>
            {wallet != null &&
                getTableData()
            }
            <Modal show={showModal} handleClose={handleCloseModal} teams={teams} handleBet={handleBetInit} />
        </div>
    );
}

export default HomePage;
