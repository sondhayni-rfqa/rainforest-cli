package main

import (
	"fmt"

	"github.com/olekukonko/tablewriter"
)

func printFolders() {
	var table [][]string
	var resBody foldersResp
	getFolders("folders.json?page_size=100", &resBody)
	fmt.Printf("\n%v\n", resBody)
	table = resBody.displayTable()
	printResource("Folders", table)
}

func printSites() {
	var table [][]string
	var resBody sitesResp
	getSites("sites.json", &resBody)
	table = resBody.displayTable()
	printResource("Folders", table)
}

func printBrowsers() {
	var table [][]string
	var resBody browsersResp
	getBrowsers("sites.json", &resBody)
	fmt.Printf("\n%v\n", resBody)
	table = resBody.displayTable()
	printResource("Folders", table)
}

func printResource(resource string, data [][]string) {
	table := tablewriter.NewWriter(out)
	table.SetHeader([]string{resource + " ID", resource + " Description"})
	table.SetBorders(tablewriter.Border{Left: true, Top: false, Right: true, Bottom: false})
	table.SetCenterSeparator("|")
	table.AppendBulk(data) // Add Bulk Data
	table.Render()
}
