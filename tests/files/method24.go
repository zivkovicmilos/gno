package main

import (
	"fmt"
	"sync"
)

type Pool struct {
	P *sync.Pool
}

func (p Pool) Get() *Buffer { return &Buffer{} }

func NewPool() Pool { return Pool{} }

type Buffer struct {
	Bs   []byte
	Pool Pool
}

var (
	_pool = NewPool()
	Get   = _pool.Get
)

func main() {
	fmt.Println(_pool)
	fmt.Println(Get())
}

// Output:
// {<nil>}
// &{[] {<nil>}}
