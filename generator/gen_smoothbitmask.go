package main
import "fmt"
//import "math"
import "strconv"

func main() {

	for i:=0 ; i<16; i++ {
		var cur = 0;
		var mask int64 = 0
		for c:=0; c<16; c++ {
			var color = int(float64(i) * (float64(c)/15.0) +.5)			
			if ( color > cur ) {
				mask = mask | 1
				cur = color
			}
			mask = mask << 1
		}
		fmt.Print("\tdc.w\t$" )
		fmt.Println(strconv.FormatInt(mask, 16))
	}
}