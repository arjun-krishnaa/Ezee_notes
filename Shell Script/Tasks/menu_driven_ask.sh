#!/bin/bash

while true
do
    echo "-----------------------------"
    echo "       System Menu"
    echo "-----------------------------"
    echo "1. Check Disk Usage"
    echo "2. Check Memory Usage"
    echo "3. Check CPU Usage"
    echo "4. Exit"
    echo "-----------------------------"

    read -p "Enter your choice [1-4]: " choice

    case $choice in
        1)
            echo "Disk Usage:"
            df -h
            ;;
        2)
            echo "Memory Usage:"
            free -h
            ;;
        3)
            echo "CPU Usage:"
            top -bn1 | grep "Cpu(s)"
            ;;
        4)
            echo "Exiting... Bye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose 1-4"
            ;;
    esac

    echo
    read -p "Press Enter to continue..."
done
