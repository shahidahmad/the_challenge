#!/bin/bash

#File: the_challenge.sh
#Author: Shahid Khan
#Date written: Sep 22 - Sep 26, 2016
#Purpose: This script displays products and their price listings. 
#Updated: October 10, 2016
#Execution time: This script takes around 5 minutes to complete its execution on my machine.

file="products.txt"
model=""
manufacturerArray=()
manufacturersCount=0
modelsCount=0
listingsCount=0 

echo -n "" | tee results.txt

#This loop creates an array of manufacturers
while read -r line;
do
	isPresent=false
     	arrCount=0
     	manufacturer=$(echo $line |cut -d':' -f3 |cut -d',' -f1 |cut -d'"' -f2)

     	if [[ ${#manufacturerArray[@]} -eq 0 ]]
     	then
		manufacturerArray[0]=$manufacturer
	  	((manufacturersCount++))
     	else
          	for ((index=0; index < ${#manufacturerArray[@]}; index++))
	  	do
              		if [[ $(echo "$manufacturer" | tr '[:upper:]' '[:lower:]') == $(echo "${manufacturerArray[$index]}" | tr '[:upper:]' '[:lower:]') ]]
              		then
                  		isPresent=true
	        		break
              		fi
          	done

		if ! $isPresent
        	then
            		manufacturerArray[$manufacturersCount]=$manufacturer
	    	 	((manufacturersCount++))
    		fi
     	fi
     	echo "Manufacturers array: ${manufacturerArray[@]}"
done<"$file"

IFS='%' #I have changed IFS - Internal Field Seperator - default value to preserve white spaces in strings.

for element in "${manufacturerArray[@]}"
do
   	modelsArray=()
   	counter=0

#Creates an array of models for an individual manufacturer
   	while read -r line;
   	do
     		model=$(echo $line |cut -d',' -f3 |cut -d':' -f2 |cut -d'"' -f2 |sed 's/[ \t]*$//')

      		modelsArray[$counter]=$model
     		((counter++))
      		((modelsCount++))
   	done< <(grep $element products.txt)  
    
   	text=$(cat listings.txt | grep -i "$element")
	
   	for modelElement in "${modelsArray[@]}"
   	do
      		product_name=$(cat products.txt | sed -n "/\($element.*$modelElement\"\).*/{s//\1/p;q;}" | cut -d":" -f2 | cut -d'"' -f2)
      		arrCount=0

      		if [[ ${#product_name} -ne 0 ]]
      		then
       			while read -r modelText;
           		do
				manufacturer=$(echo "$modelText" | cut -d'"' -f4 | cut -d' ' -f1 | tr -d ',:' | tr '[:upper:]' '[:lower:]')
				manufacElement=$(echo "$element" | tr '[:upper:]' '[:lower:]')

				if [ "$manufacturer" = "$manufacElement" ]
				then
	  				price=$( echo "$modelText" | rev | cut -d'"' -f2 |rev)
					currency=$(echo "$modelText" | rev | cut -d'"' -f6 | rev)
					isCameraManufacturer=$(echo "$modelText" | awk 'BEGIN {FS="\":\""} {print $3}' | cut -d'"' -f1 | tr '[:upper:]' '[:lower:]')
					title=$(echo "$modelText" | awk 'BEGIN {FS="\":\""} {print $2}' | awk 'BEGIN {FS="\",\"manufacturer"} {print $1}')
					listing="{\"currency\":\"$currency\", \"price\":\"$price\", \"manufacturer\":\"$manufacturer\", \"title\":\"$title\"},"
					echo "Model text:  $modelText"
					echo "++++++++++++++ Comparing $manufacturer and $isCameraManufacturer +++++++++++++++++"	
					if  [ "$manufacturer" = "$isCameraManufacturer" ]
					then
	  					priceListingsArray[$arrCount]=$listing
	  					((arrCount++))
	       					((listingsCount++))
						echo -e "$title added to price listing array\n\n"
					fi
				fi	  

      	   		done< <(echo "$text" | grep -wi "$modelElement")

	  		if [[ ${#priceListingsArray[@]} -ne 0 ]]
          		then
				listingsLastElement=${priceListingsArray[${#priceListingsArray[@]}-1]}
				listingsLastElement=$(echo $listingsLastElement | rev | cut -c2- | rev) #This statement removes comma found at the very end of the last listing in product's listings array.
				priceListingsArray[${#priceListingsArray[@]}-1]=$listingsLastElement
	      			echo -e "\nWriting the following entry to results.txt file"
				echo "{ \"product_name\": \"$product_name\", \"listings\":[${priceListingsArray[@]}]}" | tee -a results.txt
				echo -e "\n\n"
	  		else
				echo -e "\nWriting the following entry to results.txt file"
	      			echo "{ \"product_name\": \"$product_name\", \"listings\":null}" | tee -a results.txt
				echo -e "\n\n"
          		fi
      		fi
	
      		priceListingsArray=()
   	done
done

unset IFS

echo "Total number of manufacturers: $manufacturersCount"
echo "Total number of products: $modelsCount"
echo "Total number of products price listings: $listingsCount" 

