
// Install "Video Export" via Sketch -> Import Library... -> Add Library...
import com.hamoid.*;
VideoExport videoExport;

int[] deaths = new int[1000];
String[] dates = new String[1000];
boolean isRecording = true;
PImage flag;
PFont font;

String flagFilename = "usa.png";  // Flag image must be in the data folder
String countryName = "US";        // Must match name in time_series_covid19_deaths_global.csv

void setup()
{
  loadData();
  // Download https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv and save in sketch folder
  
  // How to work out the size of the flag and video:
  // Take the size of the flag image and divide the width by the height
  // The USA flag is 1235 x 650 so 1235/650 = 1.9
  // Divide the total number of deaths by that figure:
  // USA deaths was 109802 so 109802/1.9 = 57790.52
  // The square root of that value is the flag height:
  // √57790.52 = 240
  // Multiplying that value by the flag ratio gives the width:
  // 240 × 1.9 = 456
  
  maxY = 240;   // Flag height
  maxX = 456;   // Flag width
  
  // For smaller deathcounts you may need to consider doubling or tripling the size.
  
  // Add some margins and set the video size:
  size(480,270);
  
  if(isRecording)
  {
    videoExport = new VideoExport(this);
    videoExport.setFrameRate(30);
    videoExport.startMovie();
  }
  
  noStroke();
  fill(255);
  halfWidth = width/2;
  halfHeight = height/2;
  flag = loadImage("usa.png");
  flag.loadPixels();
  
  font = createFont("helvetica-normal-58c348882d347.ttf", 32);
  textFont(font);
}

int columnOfFirstDeath = 42;
int daysOfData = 0;
void loadData()
{
  String[] strings = loadStrings("time_series_covid19_deaths_global.csv");
  boolean firstRow = true;
  for(String string: strings)
  {
    String[] data = string.split(",");
    int columnCount = data.length;
    
    // Read date from first row which is in mm/dd/yyyy
    if(firstRow)
    {
      firstRow = false;
      
      for(int column = columnOfFirstDeath; column < columnCount; column++)
      {
        int day = column-columnOfFirstDeath;
        dates[day] = data[column];
        daysOfData = day;
      }
    
      continue;
    }
    
    if(!data[1].equals(countryName))
      continue;
    
    for(int column = columnOfFirstDeath; column < columnCount; column++)
    {
      int day = column-columnOfFirstDeath;
      deaths[day] = int(data[column]);
    }
  }
}

int maxX = 0;
int maxY = 0;

int lastCount = 0;
int halfWidth;
int halfHeight;

// Variables used to fade in and out text
float textAlpha1 = 0;
float textAlpha2 = 0;
float textAlpha3 = 0;


// The whole concept is based around the "lerp" (linear interpolation) variable.
// Each pixel is in flight for 3 seconds, or 90 frames.
// The lerp value for each pixel is between 0 and 1 for those 3 seconds and greater than 1 after.
// At value 0 the pixel is positioned in the middle of the screen in a grid and at  >= 1 the pixel is positioned in the flag.

void draw()
{
  pushMatrix();
    translate(13, 16); // Position the flag on the screen
    background(21, 32, 43);
    noStroke();
    
    int maxDay = frameCount / 30;
    
    for(int day = 0; day<=maxDay; day++)
    {
      int totalDeaths = deaths[day];
      float preLerp = (((frameCount/30.0) - day)*30.0)/90.0;
      float lerp = easeInOutCubic(preLerp);
      
      int dayDeaths = totalDeaths;
      if(day>0) dayDeaths = totalDeaths - deaths[day-1];    // The data is accumulative so to find the current day's deaths we need to subtract the day before's count
      if(dayDeaths == 0) continue;
      
      int gridWidth = (int)Math.sqrt(dayDeaths);
      
      int yesterdaysDeaths = totalDeaths - dayDeaths;
      
      for(int thisDeath = 0; thisDeath<dayDeaths; thisDeath++)
      {
        // Work out the grid position
        int gridX = (thisDeath % gridWidth) * 5;
        int gridY = (thisDeath / gridWidth) * 5;
        float screenGridX = halfWidth - (gridWidth/2.0) * 5 + gridX;
        float screenGridY = halfHeight - (gridWidth/2.0)* 5 + gridY;
        
        // Work out the destination flag position
        int x = ((yesterdaysDeaths + thisDeath) % maxX);
        int y = ((yesterdaysDeaths + thisDeath) / maxX);
        int flagX = (int)(x/float(maxX) * 1235);
        int flagY = (int)(y/float(maxY) * 649);
        
        // Work out the colour of the pixel, it starts of a light grey and fades to the flag colour
        color colour = flag.pixels[flagY * flag.width + flagX];
        color theColour = lerpColor(color(204, 214, 221), colour, lerp);
        
        // Now work out the in flight size and position
        float blockSize = lerp(4, 1, lerp);
        float screenX = lerp(screenGridX, x, lerp);
        float screenY = lerp(screenGridY, y, lerp);
        
        fill(theColour);
        rect(screenX, screenY, blockSize, blockSize);
      }
    }
  popMatrix();
  
  // fade in and out text:
  if(maxDay < 3)
  {
    textAlpha1 += 0.02;
    textAlpha2 += 0.02;
  }
  
  if(maxDay > 4)
    textAlpha2 -= 0.02;
  
  if(maxDay > 5 && maxDay<8)
    textAlpha3 += 0.02;
  
  if(maxDay > 9)
    textAlpha3 -= 0.02;
    
  if(maxDay > 100)
    textAlpha1 -= 0.02;
    
  if(maxDay > daysOfData)
    maxDay = daysOfData;
  
  
  int totalDeaths = deaths[maxDay];    
  int dayDeaths = totalDeaths;
  if(maxDay>0) dayDeaths = totalDeaths - deaths[maxDay-1];
  
  textSize(30);
  fill(255,255,255,255 * textAlpha2);
  textAlign(CENTER);
  text("One US COVID-19\ndeath per pixel", width/2,50);
  
  fill(255,255,255,255 * textAlpha3);
  textSize(20);
  text("PixelMoversAndMakers.com\n@KevPluck", width/2,50);
  
  fill(100,100,100,100 * textAlpha1);
  rect(0,200,width,235);
  fill(255,255,255, 255 * textAlpha1);
  textSize(20);
  textAlign(RIGHT);
  text(dates[maxDay]+"20",187,230);
  
  String plural = "s";
  if(dayDeaths == 1) plural = "  ";
  text(nfc(dayDeaths) + " death"+plural,397,230);
  
  textAlign(CENTER);
  text(nfc(totalDeaths) + " total",width/2,250);
  
  if(isRecording)
    videoExport.saveFrame();
}


float easeInOutCubic(float x) {
  if(x<0) x=0;
  if(x>1) x=1;
  return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2;
}
