const functions = require('firebase-functions');
const cors = require('cors')({origin: true});

exports.Log = functions.https.onRequest((request, response) => {
    cors(request, response, () => {
        logData = 
        {
            "body" : request.body,
            "query" : request.query,
            "ip" : request.ip,
            "url" : request.originalUrl,
            "params" : request.params,
            "method" : request.method,
            "raw_headers" : request.rawHeaders,
        }

        console.log(logData);
        response.send("Ack");
    });
});
