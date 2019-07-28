import "./main.css";
import firebase from "./firebase-app.js";
import { Elm } from "./Main.elm";
import registerServiceWorker from "./registerServiceWorker";

// Just checking envs are defined - Debug statement
console.log(process.env.ELM_APP_API_KEY !== undefined);

const firebaseConfig = {
  apiKey: process.env.ELM_APP_API_KEY,
  authDomain: process.env.ELM_APP_AUTH_DOMAIN,
  databaseURL: process.env.ELM_APP_DATABASE_URL,
  projectId: process.env.ELM_APP_PROJECT_ID,
  storageBucket: process.env.ELM_APP_STORAGE_BUCKET,
  messagingSenderId: process.env.ELM_APP_MESSAGING_SENDER_ID,
  appId: process.env.ELM_APP_APP_ID
};

firebase.initializeApp(firebaseConfig);

let counter = 1;

const app = Elm.Main.init({
  node: document.getElementById("root")
});

app.ports.sendStuff.subscribe(data => {
  console.log(JSON.stringify(data));
});

setInterval(() => {
  counter += 1;
  console.log(JSON.stringify(counter));
  app.ports.receiveStuff.send({ value: counter });
}, 1000);

registerServiceWorker();
