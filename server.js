const AWS = require("aws-sdk");
const fs = require('fs');
const readline = require('readline');
const zlib = require('zlib');


const args = process.argv;   

const s3 = new AWS.S3()

function unrecognizedCommand() {
    console.log("usage:")
    console.log("node server.js file <path>")
    console.log("node server.js stdin")
    console.log("node server.js s3 <bucket> <key>")
    process.exit(0)
}

if (args.length < 3){
    unrecognizedCommand()
}

//console.log(args[2])
let command = args[2]


async function processLineByLine() {

    var dataStream
    if (command == "file"){
        let filePath = args[3]
        dataStream = fs.createReadStream(filePath);
    }else if (command == "s3"){
        let bucket = args[3]
        let key = args[4]
        s3DataStream = s3.getObject(
            { Bucket: bucket , Key: key }
        ).createReadStream().on('error', error => {
            console.log("error getting s3 data " + error)
        });
        var z = zlib.createGunzip();
        dataStream = s3DataStream.pipe(z)

    }else if (command == "stdin"){
        dataStream =  process.stdin 
    }else {
        unrecognizedCommand()
    }

    const rl = readline.createInterface({
    input: dataStream,
    output: process.stdout,
    terminal: false,
    crlfDelay: Infinity
    });
    // Note: we use the crlfDelay option to recognize all instances of CR LF
    // ('\r\n') in input.txt as a single line break.

    for await (const line of rl) {
      jsonData = JSON.parse(line)
      //console.log ("input")
      //console.log(jsonData)
      parsed  = AWS.DynamoDB.Converter.unmarshall(jsonData.Item)
      //console.log ("output")
      console.log(JSON.stringify(parsed))
    }
}

processLineByLine();
