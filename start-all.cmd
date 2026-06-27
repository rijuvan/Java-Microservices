@echo off
setlocal

set "BASE=D:\learingpython\Javamicroservices\Java-Microservices"
set "ACTIVEMQ_HOME=D:\apacheactivemq"
set "JAVA_HOME=C:\Program Files\Microsoft\jdk-21.0.11.10-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo.
echo =====================================================
echo  BrownField PSS - Starting All Services
echo  NOTE: First run downloads Maven dependencies.
echo        Allow 3-5 min per service on first launch.
echo =====================================================
echo.

REM ---- 1. ActiveMQ ----
echo [1/6] Starting ActiveMQ broker (port 61616, console port 8161)...
start "ActiveMQ" cmd /k ""%ACTIVEMQ_HOME%\bin\activemq.bat" console"
echo       Waiting 15s for broker to initialize...
timeout /t 15 /nobreak > nul

REM ---- 2. Fares (port 8080, no broker dependency) ----
echo [2/6] Starting Fares service on port 8080...
start "Fares :8080" cmd /k "cd /d "%BASE%\fares" && mvnw.cmd spring-boot:run"
echo       Waiting 30s for Fares to start (longer on first run)...
timeout /t 30 /nobreak > nul

REM ---- 3. Search (port 8090, needs broker) ----
echo [3/6] Starting Search service on port 8090...
start "Search :8090" cmd /k "cd /d "%BASE%\search" && mvnw.cmd spring-boot:run"
echo       Waiting 25s...
timeout /t 25 /nobreak > nul

REM ---- 4. Book (port 8060, needs broker + fares) ----
echo [4/6] Starting Book service on port 8060...
start "Book :8060" cmd /k "cd /d "%BASE%\book" && mvnw.cmd spring-boot:run"
echo       Waiting 25s...
timeout /t 25 /nobreak > nul

REM ---- 5. Checkin (port 8070, needs broker + book) ----
echo [5/6] Starting Checkin service on port 8070...
start "Checkin :8070" cmd /k "cd /d "%BASE%\checkin" && mvnw.cmd spring-boot:run"
echo       Waiting 25s...
timeout /t 25 /nobreak > nul

REM ---- 6. Website (port 8001, needs all services) ----
echo [6/6] Starting Website on port 8001...
start "Website :8001" cmd /k "cd /d "%BASE%\website" && mvnw.cmd spring-boot:run"
echo       Waiting 25s for website to start...
timeout /t 25 /nobreak > nul

echo.
echo =====================================================
echo  All services launched. Smoke-testing endpoints...
echo =====================================================
echo.

REM ---- Smoke tests using curl ----
echo [TEST] ActiveMQ admin console...
curl -s -o nul -w "  ActiveMQ admin:  HTTP %%{http_code}\n" -u admin:admin http://localhost:8161/admin

echo [TEST] Fares service...
curl -s -o nul -w "  Fares actuator:  HTTP %%{http_code}\n" http://localhost:8080/actuator/health

echo [TEST] Search service...
curl -s -o nul -w "  Search actuator: HTTP %%{http_code}\n" http://localhost:8090/actuator/health

echo [TEST] Book service...
curl -s -o nul -w "  Book actuator:   HTTP %%{http_code}\n" http://localhost:8060/actuator/health

echo [TEST] Checkin service...
curl -s -o nul -w "  Checkin actuator:HTTP %%{http_code}\n" http://localhost:8070/actuator/health

echo [TEST] Website...
curl -s -o nul -w "  Website:         HTTP %%{http_code}\n" http://localhost:8001/

echo.
echo [TEST] Search API (POST /search/get)...
curl -s -X POST http://localhost:8090/search/get ^
  -H "Content-Type: application/json" ^
  -d "{\"origin\":\"NYC\",\"destination\":\"SFO\",\"flightDate\":\"22-JAN-16\"}" ^
  -w "\n  Search API: HTTP %%{http_code}\n"

echo.
echo =====================================================
echo  Service URLs:
echo   Website:        http://localhost:8001
echo   Fares API:      http://localhost:8080/swagger-ui/index.html
echo   Search API:     http://localhost:8090/swagger-ui/index.html
echo   Book API:       http://localhost:8060/swagger-ui/index.html
echo   Checkin API:    http://localhost:8070/swagger-ui/index.html
echo   ActiveMQ UI:    http://localhost:8161  (admin/admin)
echo =====================================================
echo.
pause
