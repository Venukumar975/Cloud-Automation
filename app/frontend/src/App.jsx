import React, { useState } from 'react';

const App = () => {
    const [inputText, setInputText] = useState('');
    const [results, setResults] = useState({
        word_count: 0,
        char_count: 0,
        avg_word_length: 0.00,
    });
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState(null);

    // --- AWS CONFIGURATION ---
    // this is a comment brooo
    // STEP 1: When testing locally, keep this as 'http://localhost:3000'
    // STEP 2: When deploying to S3, change this to your EC2 Public IP or Load Balancer DNS
    // Example: 'http://54.123.45.67:3000' or 'http://my-load-balancer.amazonaws.com'
    const BACKEND_HOST = 'hosting-template-alb-22022400.ap-south-1.elb.amazonaws.com';
    
    const API_URL = `${BACKEND_HOST}/api/analyze`; 

    const handleAnalyze = async () => {
        setError(null);
        setIsLoading(true);

        const textToAnalyze = inputText.trim();

        if (textToAnalyze === '') {
            setError('Please enter some text to analyze.');
            setIsLoading(false);
            return;
        }

        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ text: textToAnalyze }),
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || `Server error: ${response.status}`);
            }

            const data = await response.json();
            setResults(data);

        } catch (err) {
            console.error('Fetch Error:', err);
            setError(`Failed to connect to backend at ${API_URL}. Is the server running?`);
            setResults({ word_count: 0, char_count: 0, avg_word_length: 0.00 });
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gray-100 p-4 md:p-8 flex items-start justify-center">
            <div className="w-full max-w-4xl bg-white shadow-xl rounded-xl p-6 md:p-10 space-y-8">
                <h1 className="text-3xl md:text-4xl font-extrabold text-blue-600 text-center border-b-2 pb-4 border-blue-100">
                    Text Analyzer 
                </h1>

                <div className="space-y-4">
                    <label htmlFor="text-input" className="block text-lg font-medium text-gray-700">
                        Paste your text here:
                    </label>
                    <textarea
                        id="text-input"
                        value={inputText}
                        onChange={(e) => setInputText(e.target.value)}
                        rows="8"
                        placeholder="The quick brown fox jumps over the lazy dog."
                        className="w-full p-4 border-2 border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500 transition duration-150 shadow-inner resize-none"
                    ></textarea>

                    <button
                        onClick={handleAnalyze}
                        disabled={isLoading}
                        className={`w-full py-3 px-6 rounded-lg text-white font-semibold transition duration-300 transform hover:scale-[1.01] shadow-lg 
                            ${isLoading ? 'bg-gray-400 cursor-not-allowed' : 'bg-green-600 hover:bg-green-700 active:bg-green-800'}`}
                    >
                        {isLoading ? 'Analyzing...' : 'Analyze Text'}
                    </button>
                </div>

                {error && (
                    <div className="p-4 bg-red-100 border border-red-400 text-red-700 rounded-lg" role="alert">
                        <p className="font-bold">Error:</p>
                        <p>{error}</p>
                    </div>
                )}

                <div className="space-y-4 pt-4 border-t border-gray-200">
                    <h2 className="text-2xl font-bold text-gray-800">Results</h2>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <ResultCard title="Word Count" value={results.word_count} color="blue" />
                        <ResultCard title="Total Characters" value={results.char_count} color="purple" />
                        <ResultCard title="Avg. Word Length" value={results.avg_word_length} format="toFixed(2)" color="teal" />
                    </div>
                </div>
            </div>
        </div>
    );
};

const ResultCard = ({ title, value, color, format }) => {
    let formattedValue = value;
    if (format === 'toFixed(2)') formattedValue = parseFloat(value).toFixed(2);
    const baseClasses = `bg-${color}-50 text-${color}-800 border-l-4 border-${color}-500`;
    return (
        <div className={`p-5 rounded-lg shadow-md ${baseClasses}`}>
            <p className="text-sm font-medium uppercase">{title}</p>
            <p className="text-4xl font-extrabold mt-1">{formattedValue}</p>
        </div>
    );
};

export default App;