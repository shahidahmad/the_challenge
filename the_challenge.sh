#!/bin/bash

#File: the_challenge.sh
#Author: Shahid Khan
#Date written: Sep 22 - Sep 26, 2016
#Purpose: This script displays products and their price listings. 
#Execution time: the_challenge.sh takes approximately 4 minutes and 20 seconds to finish its execution on my machine i.e MacBook Pro 2.5GHz Intel Core i5 with Yosimite operating system.

file="products.txt"
model=""
manufacturerArray=()
manufacturersCount=0
modelsCount=0
listingsCount=0 

echo -n "" | tee results.txt

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
#             		echo "comparing " $(echo "$manufacturer" | tr '[:upper:]' '[:lower:]') " and " $(echo "${manufacturerArray[$index]}" | tr '[:upper:]' '[:lower:]')
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

for element in "${manufacturerArray[@]}"
do
   	modelsArray=()
   	counter=0

   	while read -r line;
   	do
     		model=$(echo $line |cut -d',' -f3 |cut -d':' -f2 |cut -d'"' -f2 |sed 's/[ \t]*$//')

      		modelsArray[$counter]=$model
     		((counter++))
      		((modelsCount++))
   	done< <(grep $element products.txt)  
    
   	echo -e "Manufacture: $element\n, $element models: ${modelsArray[@]}"

   	text=$(cat listings.txt | grep -i "$element")
	
   	for modelElement in "${modelsArray[@]}"
   	do
      		product_name=$(cat products.txt | sed -n "/\($element.*$modelElement\"\).*/{s//\1/p;q;}" | cut -d":" -f2 | cut -d'"' -f2)
      		echo "product_name: $product_name"
      		echo "product_model: $modelElement"
      		arrCount=0

      		if [[ ${#product_name} -ne 0 ]]
      		then 
       			while read -r modelText;
           		do
				echo "model text: $modelText"
				manufacturer=$(echo "$modelText" | cut -d'"' -f4 | cut -d' ' -f1 | tr -d ',:' | tr '[:upper:]' '[:lower:]')
				manufacElement=$(echo "$element" | tr '[:upper:]' '[:lower:]')
				echo "comparing $manufacturer and $manufacElement"

				if [ "$manufacturer" = "$manufacElement" ];
				then
	  				price=$( echo "$modelText" | rev | cut -d'"' -f2,6 |rev)
	  				price=$(echo $price | awk -F '"' '{print $2$1 " "}')
          				echo "$price added to $modelElement pricelistings array"
	  				priceListingsArray[$arrCount]=$price
	  				((arrCount++))
	       				((listingsCount++))
				fi	  
      	   		done< <(echo "$text" | grep -wi "$modelElement")

	  		if [[ ${#priceListingsArray[@]} -ne 0 ]]
          		then
	      			echo -e "{ \"product_name\": \"$product_name\", \"listing\":\"${priceListingsArray[@]}\"}" | tee -a results.txt
	  		else
	      			echo -e "{ \"product_name\": \"$product_name\", \"listing\":null}" | tee -a results.txt
          		fi
      		fi
	
      		priceListingsArray=()
   	done
done

echo "Total number of manufacturers: $manufacturersCount"
echo "Total number of products: $modelsCount"
echo "Total number of products price listings: $listingsCount" 
