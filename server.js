const AWS = require("aws-sdk");
const fs = require('fs');

const args = process.argv;   

if (args.length < 3){
  console.log("Provide a file path")
  process.exit(0)
}
console.log(args[2])

filePath = args[2]
fs.readFile(filePath , 'utf8' , (err, data) => {
  if (err) {
    console.error(err)
    return
  }
  //console.log(data)
  parsed  = AWS.DynamoDB.Converter.unmarshall(JSON.parse(data))
  console.log(parsed)

})

