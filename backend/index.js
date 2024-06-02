import express, { json } from 'express';
import Web3 from 'Web3';
import cors from 'cors';
const app = express();
const port = 3001; // or any port you prefer
app.use(cors());
 
// Define routes
app.get('/getGameDetail', (req, res) => {
    const matchId = req.query.matchId;
    if (matchId) {
        for (let index = 0; index < games.length; index++) {
            const element = games[index];
            if (element.matchId == matchId) {
                element.status = "completed";
                res.json(element);
                return;
            }
        }
    } else {
        res.status(500).send({});
    }
});

// Define routes
app.get('/get_games', (req, res) => {
    try {
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Cache-Control', 'no-cache'); 
        const _games = ['Chelsea 1 vs Liverpool1', 100000000000000, Math.floor((Date.now() + 2 * 60 * 1000) / 1000)]; 
        console.log("..............get_games");
        res.status(200).send(_games);
    } catch (error) {
        console.error('Error fetching games:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Define routes
app.get('/update_games', (req, res) => {
    try {
        console.log(req.query.gameId);
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Cache-Control', 'no-cache');
        let futureTimestamp = Date.now() + 3 * 60 * 1000;
        futureTimestamp = Math.floor(futureTimestamp / 1000);
        const _games = ["started", req.query.gameId == 0 ? 2 : req.query.gameId, futureTimestamp];  
        res.status(200).send(_games);
    } catch (error) {
        console.error('Error fetching games:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});


// Define routes
app.get('/settle_games', (req, res) => {
    try {
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Cache-Control', 'no-cache');
        const _games = ["complete", 3];  
        res.status(200).send(_games);
    } catch (error) {
        console.error('Error fetching games:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Start the server
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});