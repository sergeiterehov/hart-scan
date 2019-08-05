import processing.serial.*;

Serial ard;
float timeOffset;
ArrayList<PVector> data;
float timePointer;
float zoom;
// Seconds per window
float spw;

float saveTimeEnd;

void setup() {
  //size(500, 300);
  fullScreen();
  
  surface.setTitle("SergeiTerehov Hart Scan");
  
  spw = 5;
  timePointer = 0;
  
  data = new ArrayList();
  
  thread("updateDataLoop");
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
  }

  zoom = width / spw;

  clear();
  
  drawGrid();
  drawTimePointer();
  drawData();
  drawUI();
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();

  timePointer += 0.02f * e;

  if (timePointer > 0) {
    timePointer = 0;
  }
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
  
  else if (key == 'q' || key == 'Q') {
    if (ard != null) {
      ard.stop();
      ard = null;
    }
  }

  else if (key == '+' || key == '=') {
    spw -= 0.5f;
  }
  
  else if (key == '-') {
    spw += 0.5f;
  }
}

void drawUI() {
  if (ard == null) {
    drawSelectDeviceUI();
  }
  
  drawCursorUI();
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
  float timeMousePointer = 1.0f * spw * mouseX / width - timePointer;
  float x = (timePointer + timeMousePointer) * zoom;

  stroke(100, 100, 255);
  line(
    x, 0,
    x, height
  );
  fill(255, 255, 255);
  textSize(30);
  textAlign(LEFT, BOTTOM);
  text(
    String.format("%.2f сек.", timeMousePointer),
    x + 20, mouseY
  );
}

void drawGrid() {
  stroke(40, 40, 40);

  for (float i = 0; i <= 10; i++) {
    line(
      0, i / 10 * height,
      width, i / 10 * height
    );
  }

  stroke(40, 40, 40);

  for (float i = -10; i <= (spw + 1) * 10; i++) {
    float offset = timePointer - int(timePointer);
    float x = (offset + i / 10.0f) * zoom;

    line(
      x, 0,
      x, height
    );
  }
  
  stroke(80, 80, 80);
  fill(100, 100, 100);
  textAlign(LEFT, BOTTOM);
  textSize(14);
  
  for (float i = -1; i <= spw + 1; i++) {
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
      (a.x + timePointer) * zoom, a.y * height,
      (b.x + timePointer) * zoom, b.y * height
    );
  }
}

float getTime() {
  return millis() / 1000.0f + timeOffset;
}

void resetData() {
  timeOffset = -millis() / 1000.0f;
  timePointer = -getTime();

  data.clear();
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
