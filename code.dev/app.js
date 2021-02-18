const axios = require('axios');

var markets = {
	binance: {
		url: 'https://api.binance.com',
		apiKeyName: 'binance-api-key',
		apiSecretName: 'binance-api-secret',
		testUrlExtension: '/api/v3/ping',
		symbolListUrlExtension: '/api/v3/exchangeInfo'
	}
}

getSymbolList('binance');
//getSymbolPrice('binance', 'BNBUSDT');

// FUNCTIONS

function getSymbolList(marketName) {
	console.log('Getting symbol list from ' + marketName + ' network:');
	var acGetSymbolList = {
		method: 'get',
		url: markets[marketName].url + markets[marketName].symbolListUrlExtension
	};
	axios(acGetSymbolList)
		.then(function (response) {
//			for (var symbolIndex = 0; symbolIndex < response.data.symbols.length(); symbolIndex++){
//				console.log(response.data.symbols[symbolIndex].symbol);
//				getSymbolPrice(marketName, response.data.symbols[symbolIndex].symbol);
//			}
console.log(response.data.symbols);
		})
		.catch(function (error) {
			console.log('--> failed to get symbol list');
		});
}

function getSymbolPrice(marketName, symbolName) {
	var acGetSymbolPrice = {
		method: 'get',
		url: markets[marketName].url + '/api/v3/ticker/price?symbol=' + symbolName
	};
	axios(acGetSymbolPrice)
		.then(function (response) {
			console.log( response.data.symbol + ': ' + response.data.price);
		})
		.catch(function (error) {
			console.log(error);
		});
}




function testConnection(marketName) {
	console.log('Testing ' + marketName + ' network  connection:');
	var acConTest = {
		method: 'get',
		url: markets[marketName].url + markets[marketName].testUrlExtension
	};
	axios(acConTest)
		.then(function (response) {
			console.log('-> Connection Test Succeeded!');
		})
		.catch(function (error) {
			console.log('-> Connection Test Failed!');
		});

}
