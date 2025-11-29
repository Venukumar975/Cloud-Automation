/**
 * Express Backend Server (server.js)
 * Upload this file to your EC2 instance.
 * Run 'node server.js' to start it.
 */

const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const PORT = 3000; 

app.use(bodyParser.json());

// --- CORS CONFIGURATION ---
// Allows your S3 frontend to talk to this backend
app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*'); 
    res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    next();
});

// Text Analysis Logic
function processText(text) {
    const char_count = text.length;
    const sanitizedText = text.replace(/[^a-zA-Z0-9\s]/g, ' ').toLowerCase();
    const wordsList = sanitizedText.split(/\s+/).filter(word => word.length > 0);
    const word_count = wordsList.length;
    const totalWordLength = wordsList.reduce((sum, word) => sum + word.length, 0);
    
    let avg_word_length = 0.0;
    if (word_count > 0) {
        avg_word_length = totalWordLength / word_count;
    }
    
    return {
        word_count,
        char_count,
        avg_word_length: parseFloat(avg_word_length.toFixed(2))
    };
}

// API Endpoint
app.post('/api/analyze', (req, res) => {
    const inputText = req.body.text || "";
    if (!inputText) return res.status(400).json({ error: "No text provided." });
    
    const results = processText(inputText);
    res.json(results);
});

app.listen(PORT, () => {
    console.log(`Backend API running on port ${PORT}`);
});