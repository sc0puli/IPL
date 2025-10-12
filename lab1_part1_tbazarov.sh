#!/bin/bash
# 3 slide
echo $SHELL
echo $BASH_VERSION
echo $HISTFILE 
help echo

# 6 slide
echo Hello							World                    !
echo "Hello							World                    !"
echo *
echo *sh
echo *set*
echo "s*"

# 7 slide
echo 2 * 3 > 5 is a valid statement.
echo '2 * 3 > 5 is a valid statement.'
echo '2 * 3 > 5' is a valid statement.

# 8 slide
printf "%s : %d\n" "Аудитория" 4132
printf "%10s%10s\n" "String1" "String2"
printf "%-10s%-10s\n" "String1" "String2"
var=$(printf "%.*s" 11 "Bashscripting")
printf –v var "%.*s" 7 "Bashscripting"

# 9 slide
read line
echo $line

read
echo $REPLY

read line1 line2
read -n 4 line 
read -d . line

# 10 slide 
x=10
str="Stringvalue"
words='Multiple words value'
val1=10
val2=5
res=val1*val2
echo $res
res=$val1*$val2 
echo $res

declare -i val3=10 val4=5
declare -i result2
result2=val3*val4
echo $result2

# 11 slide
y=10
B=""
#x = 3
#s=String string
s="String string"

echo y value is $y
echo y value is ${y}

words='Many      spaces      between      words'
echo $words
echo "$words"

x=3 y=4
r=$(( $x + $y)) # => 7
echo $r
r=$(( ${x} + ${y})) # => 7
echo $r
r=$(( x + y)) # => 7
echo $r
#r=$( x + y )

a='ls'
echo $a

a=$(ls)
echo $a

x=4
b=$(( $x + 1 + 5))
d=$( expr $x + 1 + 5)
echo $b $d

# 12 slide
x=4 
let c=$x*2+1+5
let c='(2+3)*4'
echo $c
let c="(2+3)*$x"
echo $c
d=$( expr $x \* 2 + 1 + 5 )

# 13 slide
echo ca{r,n,t}s
echo ca{r,n,t,{f,k,v}e}s
echo {1..8}
echo {a..h}
ls *.{csh,sh}

#17 slide
fname=$PWD
if [ -d $fname ]; then
	echo "$fname is a directory"
else
	echo "$fname is not adirectory"
fi

#18 slide
read -p "Enter your department: " dept
if [ "$dept" = "inel" ]; then 
	echo "Please proceed with doing the lab"
else 
	echo "You a re f o rb i d d en t o pr o c eed"
fi

read -p "Enter your department: " dept
if [[ "$dept" == in* ]]; then 
	echo "Please proceed with doing the lab"
else 
	echo "You a re f o rb i d d en t o pr o c eed"
fi

read -p "Enter x : " x
if [ "$x" = 0 ]; then 
	echo "Zero"
else 
	echo "Nonzero"
fi

read -p "Enter x : " x
if [ $x -eq 0 ]; then 
	echo "Zero"
else 
	echo "Nonzero"
fi

read -p "Enter x : " x
if [ $x -gt 0 ]; then 
	echo "Positive"
else 
	echo "Negative or zero"
fi

#19 slide
if [ $x -gt 0 ]; then 
	echo "Positive"
else 
	if [ $x -eq 0 ]; then 
		echo "zero"
	else 
		echo "Negative"
	fi
fi

if [ $x -gt 0 ]; then 
	echo "Positive"
elif [ $x -eq 0 ]; then 
	echo "zero"
else 
	echo "Negative"
fi

if [ $x -lt 0 ] || [ $x -ne 0 ]; then 
	echo "Nonzero"
else 
	echo "zero"
fi

if [ $x -le 0 ] && [ $x -ge 0 ]; then 
	echo "zero"
else 
	echo "Nonzero"
fi

#20 slide
export LC_COLLATE=C
echo "Press a key: "
IFS= read -n 1 k
case "${k}" in
	[a-z] ) echo " lowercase letter " ;;
	[A-Z] ) echo " uppercase letter " ;;
	[0-9] ) echo " digit " ;;
   	" " ) echo " space " ;;
	"." | "," | ";" ) echo "separator" ;;
	* ) echo "Something different" ;;
esac

#21 slide
for i in 1 2 3 4 5
do
	echo "Value is $i"
done
echo
for i in {1..5}
do
	echo "Value is $i"
done
echo
for i in {0..20..2} # С версии bash4.0
do
	echo "Value is $i"
done
echo
for (( c=1; c<=5; c++ ))
do
	echo "Value is $c "
done

echo

for ((;;)) 
do
	read var
	if [ "$var" = "." ]; then 
		break
	fi
done

# 22 slied
seq -s " " 10
seq -s ":" 10
seq -s " " -w 10
seq -f "%.1f" -s " " 0 0.1 1

for i in $(seq 20)
do
	echo "Value is $i"
done

for i in $(seq 1 2 20)
do
	echo "Value is $i"
done

#23 slied 
n=1 
while [ $n -le 5 ]
do
	echo "Value is $n"
	n=$(( n+1 ))
done

n=1 
until [ $n -ne 6 ]
do
	echo "Value is $n"
	n=$(( n+1 ))
done

a=10 b=5
echo "What should we do with variables a and b?"
select choice in Add Sub Mult Div Exit
do
	case $choice in
		Add ) echo "a+b=$(( $a+$b ))" ;;
		Sub ) echo "a-b=$(( $a-$b ))" ;;
		Mult ) echo "a*b=$(( $a*$b ))" ;;
		Div ) echo "a/b=$(( $a/$b ))" ;;
		Exit ) break ;;
	esac
done

#24 slide
arr=(One Two Three Four Five Six Seven Eight Nine Ten Eleven)

echo ${arr[2]}
arr[2]=NotThree
echo ${arr[2]}

unset arr[5]
echo ${arr[5]}

unset arr
echo $arr

for i in "${arr[@]}";
do
	echo $i 
done

echo ${!arr[*]}

echo ${#arr[@]}

echo ${#arr[3]}