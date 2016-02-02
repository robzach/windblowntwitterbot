/*
 Windblown twitterbot, made for Golan Levin's Interactive Art and Computational
 Design class at CMU, spring 2016.
 
 Looks up the most recent wind speed and bearing near campus and uses that
 data to blow some randomly colored balls around in a box. Tweets the data
 as well as the image to @2prongnoground .
 
 Incorporates code from Charlotte, featured at <http://cmuems.com/2014a/cfs/12/04/final-tiny-fits-of-rage/>
 
 By Robert Zacharias, with extremely generous help from Golan Levin
 2/28/16
 */


import com.temboo.core.*;
import com.temboo.Library.Twitter.Tweets.*;
import javax.xml.bind.DatatypeConverter;

TembooSession session = new TembooSession("username", "myFirstApp", "userkey");

JSONObject json;
int direction;
float speed;
String tweetText;
long timer = millis();
int wait = 1000*60*15; // 15 minute timer

void setup() {
  size(400, 400);
  pixelDensity(2); // prettier images on a Retina display
  background(255);

  // run on startup
  JSONlookup();
  runUpdateWithMediaChoreo();
}

void draw() {
  // run every 15 minutes in normal operation
  if (millis() - timer > wait) {
    JSONlookup();
    runUpdateWithMediaChoreo();
    timer = millis();
  }
}

void runUpdateWithMediaChoreo() {

  // compose text to tweet
  if (speed < 15) {
    tweetText = speed + "mph from " + direction + " degrees";
  } else tweetText = speed + "mph from " + direction + " degrees. Windy!";

  // Temboo stuff
  UpdateWithMedia updateWithMediaChoreo = new UpdateWithMedia(session);
  updateWithMediaChoreo.setStatusUpdate(tweetText);
  updateWithMediaChoreo.setConsumerKey("consumerkey");
  updateWithMediaChoreo.setAccessToken("accesstoken");
  updateWithMediaChoreo.setConsumerSecret("consumersecret");
  updateWithMediaChoreo.setAccessTokenSecret("accesstokensecret");

  // note that this is the image transmitter; it calls a function to generate the picture
  updateWithMediaChoreo.setMediaContent(generatedBase64String());

  UpdateWithMediaResultSet updateWithMediaResults = updateWithMediaChoreo.run();

  println(updateWithMediaResults.getLimit());
  println(updateWithMediaResults.getRemaining());
  println(updateWithMediaResults.getReset());
  println(updateWithMediaResults.getResponse());
}

// function to generate appropriate image type for Twitter upload
String generatedBase64String() {

  // math that will push on the generated circled according to the windspeed and direction
  float theta = radians(direction);
  float xmultiplier = speed/5 * sin(theta);
  float ymultiplier = speed/5 * cos(theta);

  // generate 4000 circles of different sizes and then push them according to the wind
  for (int i = 0; i<4000; i++) {
    float r = random(255);
    float g = random(255);
    float b = random(255);
    float x = random(width);
    float y = random(height);
    x += random(width*xmultiplier);
    x = constrain(x, 10, width-10); // keep balls away from outside edges
    y += random(height*ymultiplier);
    y = constrain(y, 10, height-10);
    fill(r, g, b, 128);
    ellipse(x, y, g/12, g/12); //  using one of the random variables for size
  }

  // save generated image, turn it into a base-64 image
  saveFrame("frame.gif");
  delay(1000); // allows time for file to write to disk so it can then be read
  byte b[] = loadBytes("frame.gif");
  String b64 = DatatypeConverter.printBase64Binary(b); // converts to image filetype Twitter wants
  return b64; // this function returns the generated image as a string
}

void JSONlookup() {
  // find latest weather data
  json = loadJSONObject("http://api.openweathermap.org/data/2.5/weather?zip=15206,us&appid=44db6a862fba0b067b1930da0d769e98");
  while (json == null); // hold here until data is retrieved
  JSONObject wind = json.getJSONObject("wind");
  direction = wind.getInt("deg"); // modifying global variables
  speed = wind.getFloat("speed");
  println(speed + "mph at " + direction + " degrees");
}