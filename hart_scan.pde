import processing.serial.*;

Serial ard;
// Data time offset
float timeOffset;
ArrayList<PVector> data;

ArrayList<PVector> markers;

// Offset for zero point
float timePointer;
float zoom;
// Seconds per window
float spw;

// End of data times position
float saveTimeEnd;
// Mouse position in seconds
float timeMousePointer;

boolean isFollowCursor;

void setup() {
  frameRate(30);

  //size(500, 300);
  fullScreen();
  
  surface.setTitle("SergeiTerehov Hart Scan");
  
  spw = 5;
  timePointer = 0;
  
  data = new ArrayList();
  markers = new ArrayList();
  
  //thread("updateDataLoop");
}

void updateDataLoop() {
  while (true) {
    updateData();

    delay(5);
  }
}

void draw() {
  if (spw <= 0.1f) {
    spw = 0.1f;
  } else if (spw >= 3600.0f) {
    spw = 3600.0f;
  }

  if (isFollowCursor) {
    timePointer = - getTime() + 0.8 * spw;
  }

  if (timePointer > 0) {
    timePointer = 0;
  }

  zoom = width / spw;
  timeMousePointer = 1.0f * spw * mouseX / width - timePointer;

  clear();
  
  drawGrid();
  drawMarkers();
  drawTimePointer();
  drawData();
  drawUI();
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();

  timePointer += 0.02f * spw * e;
}

void keyPressed() {
  if (key == 'e' || key == 'E') {
    saveTimeEnd = getTime();
    selectOutput("Файл для сохранения:", "saveFileSelected");
  }

  else if (key == 's' || key == 'S') {
    thread("resetData");
  }
  
  else if (key == ' ') {
    if (ard == null) {
      timePointer = 0;
    } else {
      timePointer = -(getTime() - 0.25f * spw);
    }
  }
  
  else if (key == 'o' || key == 'O') {
    if (ard != null) {
      ard.stop();
      ard = null;
    }

    selectInput("Выберите файл для просмотра:", "openFileSelected");
  }
  
  else if (key >= '0' && key <= '9') {
    if (ard == null) {
      ard = new Serial(this, Serial.list()[key - '0'], 115200);
      resetData();
    }
  }
  
  else if (key == 'm' || key == 'M') {
    markers.add(new PVector(timeMousePointer, mouseY));
  }
  
  else if (key == 'x' || key == 'X') {
    markers.clear();
  }
  
  else if (key == 'q' || key == 'Q') {
    if (ard != null) {
      ard.stop();
      ard = null;
      
      isFollowCursor = false;
    }
  }
  
  else if (key == 'f' || key == 'F') {
    isFollowCursor = ! isFollowCursor;
  }

  else if (key == '+' || key == '=') {
    spw /= 1.1f;
    timePointer -= (timePointer + timeMousePointer) * 0.1f / 1.1;
  }
  
  else if (key == '-') {
    spw *= 1.1f;
    timePointer += (timePointer + timeMousePointer) * 0.1f;
  }
  
  else if (key == CODED) {
    if (keyCode == LEFT) {
      timePointer += 0.8 * spw;
    }
    
    else if (keyCode == RIGHT) {
      timePointer -= 0.8 * spw;
    }
  }
}

void drawUI() {
  if (ard == null) {
    drawSelectDeviceUI();
  }

  drawCursorUI();
}

void serialEvent(Serial dev) {
  if (dev == ard) {
    updateData();
  }
}

void drawSelectDeviceUI() {
  String[] list = Serial.list();

  fill(130, 130, 130, data.size() > 0 ? 80 : 255);
  textSize(30);
  textAlign(LEFT, TOP);
  
  for (int i = 0; i < list.length; i++) {
    text(String.format("[%d] %s", i, list[i]), 10, i * 30);
  }
}

void drawCursorUI() {
  stroke(100, 100, 255);
  line(
    mouseX, 0,
    mouseX, height
  );
  fill(255, 255, 255);
  textSize(30);
  textAlign(LEFT, BOTTOM);
  text(
    String.format(
      "%." + (spw > 50 ? 1 : spw > 4 ? 2 : 3) + "f сек.",
      timeMousePointer
    ),
    mouseX + 20, mouseY
  );
}

void drawGrid() {
  stroke(30, 30, 30);

  for (float i = 0; i <= 10; i++) {
    line(
      0, i / 10 * height,
      width, i / 10 * height
    );
  }

  if (spw <= 20) {
    stroke(30, 30, 30);
  
    for (float i = -10; i <= (spw + 1) * 10; i++) {
      float offset = timePointer - int(timePointer);
      float x = (offset + i / 10.0f) * zoom;
  
      line(
        x, 0,
        x, height
      );
    }
  }
  
  stroke(80, 80, 80);
  fill(100, 100, 100);
  textAlign(LEFT, BOTTOM);
  textSize(14);
  
  float dSecond = spw > 1000 ? 60 : spw > 200 ? 10 : 1;
  
  for (float i = -1; i <= spw + 1; i += dSecond) {
    float offset = timePointer - int(timePointer);
    float x = (offset + i) * zoom;

    line(
      x, 0,
      x, height
    );
    
    text(int(-timePointer + i), x, height);
  }
}

void drawTimePointer() {
  if (ard == null) {
    return;
  }

  stroke(90, 40, 40);
  line(
    (timePointer + getTime()) * zoom, 0,
    (timePointer + getTime()) * zoom, height
  );
  
  if (saveTimeEnd > 0) {
    stroke(40, 100, 40);
    line(
      (timePointer + saveTimeEnd) * zoom, 0,
      (timePointer + saveTimeEnd) * zoom, height
    );
  }
}

void drawMarkers() {
  stroke(150, 90, 30);
  fill(150, 90, 30);
  textSize(20);

  for (int i = 0; i < markers.size(); i++) {
    PVector marker = markers.get(i);
    float x = (timePointer + marker.x) * zoom;

    line(
      x, 0,
      x, height
    );
    text(
      String.format("%.3f", marker.x),
      x + 10, marker.y
    );
  }
}

void drawData() {
  stroke(255, 255, 255);
  
  for (int i = 1; i < data.size(); i++) {
    PVector a = data.get(i - 1);
    PVector b = data.get(i);
    
    float bPos = (b.x + timePointer) * zoom;
    
    if (bPos < 0 || bPos > width) {
      continue;
    }

    line(
      (a.x + timePointer) * zoom, (1 - a.y) * height,
      (b.x + timePointer) * zoom, (1 - b.y) * height
    );
  }
}

float getTime() {
  if (ard == null) {
    return 0;
  }

  return millis() / 1000.0f + timeOffset;
}

void resetData() {
  timeOffset = -millis() / 1000.0f;
  timePointer = -getTime();

  data.clear();
  markers.clear();
}

void updateData() {
  if (ard == null) {
    return;
  }

  if (ard.available() == 0) {
    return;
  }
  
  String src = ard.readStringUntil(10);
  
  if (src == null) {
    return;
  }
  
  float value;
  
  try {
    value = parseFloat(src.trim()) / 1023.0f;
  } catch (Exception e) {
    return;
  };
  
  float time = getTime();
  
  data.add(new PVector(time, value));
}

void saveFileSelected(File selection) {
  if (selection == null) {
    return;
  }
  
  String path = selection.getAbsolutePath();
  
  PrintWriter file = createWriter(path);
  
  for (int i = 0; i < data.size(); i++) {
    PVector item = data.get(i);
    
    if (saveTimeEnd < item.x) {
      break;
    }

    file.println(
      String.format("%,6f", item.x) + ";" +
      String.format("%,6f", item.y)
    );
  }
  
  file.flush();
  file.close();
}

void openFileSelected(File selected) {
  if (selected == null) {
    return;
  }
  
  String path = selected.getAbsolutePath();
  
  BufferedReader file = createReader(path);
  String line = null;
  
  data.clear();
  
  try {
    while (true) {
      line = file.readLine();
      
      if (line == null) {
        break;
      }
      
      String[] cells = split(line, ";");
      
      if (cells.length < 2) {
        continue;
      }
      
      PVector item = new PVector(
        float(cells[0].replace(",", ".")),
        float(cells[1].replace(",", "."))
      );
      
      data.add(item);
    }
  } catch (Exception e) {
    return;
  };
  
  if (data.size() > 0) {
    timePointer = data.get(0).x;
  }
}
