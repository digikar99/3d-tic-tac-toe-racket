;#lang racket

;(require "board.rkt")
;(provide (all-defined-out))
;;; a demo of a function that check of a winning position is formed

;;; Since, in the current turn, a line can only be formed, if it includes
;;; the last played position, we take this position, and check from the
;;; corresponding beginning of every such line.

(define (make-3d-vector x y z init)
  (build-vector z
                (lambda (k)
                  (build-vector y
                                (lambda (j)
                                  (make-vector x init))))))

(define (3d-vector-set! vec x y z val)
  (vector-set! (vector-ref (vector-ref vec z) y) x val))

(define (3d-vector-ref vec x y z)
  ;; pos - a list of x y z coordinates, in that order
  (vector-ref (vector-ref (vector-ref vec z) y) x))

(define (3d-vector-copy vec)
  (define z-max (vector-length vec))
  (define y-max (vector-length (vector-ref vec 0)))
  (build-vector z-max
                (lambda (z)
                  (build-vector y-max
                                (lambda (y)
                                  (vector-copy
                                   (vector-ref (vector-ref vec z) y)))))))

;; note that inner-most-list comprises the x-coordinates

(define board 0) ; board is an integer; 2 bits each represent the state of each cell
  ;(make-3d-vector 4 4 4 0))
;  '(((1 1 1 1) (0 0 0 0) (0 0 0 0) (0 0 0 0))
;  ((0 0 0 0) (0 0 0 0) (0 0 0 0) (0 0 0 0))
;  ((0 0 0 0) (0 0 0 0) (0 0 0 0) (0 0 0 0))
;  ((0 0 0 0) (0 0 0 0) (0 0 0 0) (0 0 0 0))))
; unset state is 0; other states are -1 and 1.

(define last-played-pos '(0 0 0))
(define pcturn #t)

(define (get-value board pos)
  (define state (remainder (quotient board (expt 4 (+ (car pos)
                                                      (* 4 (cadr pos))
                                                      (* 16 (caddr pos)))))
                           4))
  (cond ((= state 2) 1)
        ((= state 3) -1)
        (else 0)))
  ;; pos - a list of x y z coordinates, in that order
  ;(vector-ref (vector-ref (vector-ref board (caddr pos)) (cadr pos)) (car pos)))
;  (list-ref (list-ref (list-ref board (caddr pos)) (cadr pos)) (car pos)))

(define (display-board board)
  (display "(")
  (for ((i 4))
    (display "(")
    (for ((j 4))
      (display "(")
      (for ((k 4))
        (display (get-value board (list k j i))))
      (display ")"))
    (displayln ")"))
  (displayln ")"))

;(define (display-board board)
;  (for ((i 4)) (displayln (vector-ref board i))))

(define (set!-value board pos val)
  ;(vector-set! (vector-ref (vector-ref board (caddr pos)) (cadr pos)) (car pos) val))
  (cond ((= 0 (get-value board pos))
         (define part (expt 4 (+ (car pos)
                                 (* 4 (cadr pos))
                                 (* 16 (caddr pos)))))
         (+ (* (+ (* (quotient board (* 4 part)) 4)
                        (cond ((= 1 val) 2)
                              ((= -1 val) 3)
                              (else "Invalid val: " val))) part)
                  (remainder board part)))
        (else (error "Position is already set: " pos))))

(define (board-copy board) board)
;  (define z-max (vector-length vec))
;  (define y-max (vector-length (vector-ref vec 0)))
;  (build-vector z-max
;                (lambda (z)
;                  (build-vector y-max
;                                (lambda (y)
;                                  (vector-copy
;                                   (vector-ref (vector-ref vec z) y)))))))

(define (list->board l)
  (define vec (list->vector l))
  (define board (make-3d-vector 4 4 4 0))
  (for/list ((i 64))
    (define z (quotient i 16))
    (define y (quotient (remainder i 16) 4))
    (define x (remainder (remainder i 16) 4))
    (set!-value board (list x y z) (vector-ref vec i)))
  board)

(define (board->list board)
  (define vec (make-vector 64 0))
  (for/list ((i 64))
    (define z (quotient i 16))
    (define y (quotient (remainder i 16) 4))
    (define x (remainder (remainder i 16) 4))
    (vector-set! vec i (get-value board (list x y z))))
  (vector->list vec))


(define (win? board lpp) ; lpp is for last played position
  ; returns #t if a player has won.

  (define n 3) ; increase n to increase size of board (board-size - 1)
  
  (define line-found #f)
 ; (define lpp last-played-pos) ; abbreviation

  (define (get-value1 pos)
    (get-value board pos))
  (define (set!-value1 pos)
    (set!-value board pos))
  
  (define (get-line init-update)
    (define gl-init (car init-update))
    (define gl-update (cadr init-update))
    ;(displayln gl-init)
    ;(displayln gl-update)
    (while/list border-not-reached? gl-update gl-init))

  (define (in-a-line? l)
    ; takes in a list of coordinates and checks if they form a complete line
    ; currently does not check if the position is unset.
    ;(displayln "In in-a-line?")
    (and (apply = (map get-value1 l)) (not (= 0 (get-value1 (car l))))))
  
  (define (border-not-reached? pos)
    ; Returns #t if pos is an invalid (in a greater sense) coordinate
    ;(display "In border-not-reached: ") (displayln pos)
    (and (>= n (car pos)) (>= n (cadr pos)) (>= n (caddr pos))))

  ;;; CAN BE A BOTTLENECK WITHOUT VECTORS
  (define (update x y z)
        ; returns a procedure that tells how the init coordinates should be chamged
        ; used in check eqv method
        (lambda (pos) (list (+ x (car pos)) (+ y (cadr pos)) (+ z (caddr pos)))))
  
            
  (define (update-methods)
    ;;; returns a list of (list init and update methods) corresponding to last played position
    (define x (car lpp))
    (define y (cadr lpp))
    (define z (caddr lpp))
    
    (define (gen-axes)
      ; works out the same for x y and z directions
      (let* ((init-x (list 0 y z))
             (init-y (list x 0 z))
             (init-z (list x y 0))
             (update-x (update 1 0 0))
             (update-y (update 0 1 0))
             (update-z (update 0 0 1)))
        (list (list init-x update-x) (list init-y update-y) (list init-z update-z))))
    
    (define (gen-plane-diag)
      (append* (if (= x y) (list (list (list 0 0 z) (update 1 1 0))) '())
               (if (= z y) (list (list (list x 0 0) (update 0 1 1))) '())
               (if (= x z) (list (list (list 0 y 0) (update 1 0 1))) '())
               (if (= n (+ x y)) (list (list (list 0 n z) (update 1 -1 0))) '())
               (if (= n (+ z y)) (list (list (list x 0 n) (update 0 1 -1))) '())
               (if (= n (+ x z)) (list (list (list (list n y 0) (update -1 0 1)))) '())))
    
    (define (gen-body-diag)
      (append* (if (= x y z) (list (list (list 0 0 0) (update 1 1 1))) '())
               (if (and (= x y) (= n (+ x z)))
                   (list (list (list 0 0 3) (update 1 1 -1))) '())
               (if (and (= x z) (= n (+ x y)))
                   (list (list (list 0 3 0) (update 1 -1 1))) '())
               (if (and (= z y) (= n (+ x z)))
                   (list (list (list (list 3 0 0) (update -1 1 1)))) '())))
    
    (append (gen-axes) (gen-plane-diag) (gen-body-diag)))

  
  (define (helper)
    ; the main function of win?
    (define init-update-list (update-methods))
    ;(displayln init-update-list)
    (define (check-all-lines l) ; l would be a list of init-updates
      (cond (line-found #t)
            ((null? l) #f)
            (else
             (begin
               (set! line-found (in-a-line? (get-line (car l))))
               (check-all-lines (cdr l))))))
    (check-all-lines init-update-list)
;    (if line-found
;        (if (= player 1) (displayln "Player 1 won") (displayln "Player 2 won"))
;        line-found)
    line-found)
    

  (helper))
      
                
;; ================== SOME HIGHER ORDER FUNCTIONS =========================

;; is until supposed to return something even when (p x) is true while entering?
;; if yes, then it isn't the same as simply until (cond) {expr}; but a do-until. 

(define (until p f x)
  ;;; applies f to p until (p x) returns true
  (if (p x) x (until p f (f x))))


(define (until/list p f x)
  ;;; applies f to p until (p x) becomes true, and returns a list
  ;;; containing all the previous results
  (if (p x) (list x) (cons x (until/list p f (f x)))))

;; returns a list containing f applied increasing number of times
;; the values are accumulated
(define (while/list p f x)
  ;(displayln x)
  ;(displayln f)
  (if (p x) (cons x (while/list p f (f x))) '()))

;; returns x even if the condition is false, unlike while.
(define (do-while p f x)
  (if (p x) (do-while p f (f x)) x))


;; rotate-r works only on pos - comprising of 3 elements
(define (rotate-l pos) (append (cdr pos) (list (car pos))))
(define (rotate-r pos) (cons (caddr pos) (list (car pos) (cadr pos))))

(define (exchange pos x y z)
  ;; exchangers coordinates at the corresponding location
  (cond ((= 1 x y) (cons (cadr pos) (cons (car pos) (cddr pos))))
        ((= 1 y z) (cons (car pos) (list (caddr pos) (cadr pos))))
        ((= 1 x z) (cons (caddr pos) (cons (cadr pos) (list (car pos)))))
        (else (error "Unknown exchange format"))))


;--------------------- These functions could not be used in the above code. -----------------------

    ;; Appreciable functions, they are. init and lpp relation makes them useless.
;      (define (all-comb update-method init)
;        ;; takes an init and update mthod that operates on its arguments in one way.
;        ;; returns a list of (list of init and update methods) that operate equivalently
;
;        ;; For example (all-comb '(1 1 0) (1 1 (+ z 1))) returns
;        ;; ((1 1 0) (1 1 (+ z 1)) (1 0 1) (1 (+ y 1) 1) (0 1 1) ((+ x 1) 1 1))
;
;        (define (rem-dup-init l)
;          ; removes elements of the pre-final lists if they are the same
;          (if (null? l)
;                '()
;                (cons ())))
;        
;        (let* ((init-1 init)
;               (init-2 (shift-r init-1))
;               (init-3 (shift-r init-2))
;               (update-1 update-method)
;               (update-2 (rotate-update-r update-1))
;               (update-3 (rotate-update-r update-3))
;               (init-4 (exchange init-1 1 1 0))
;               (init-5 (exchange init-2 1 1 0))
;               (init-6 (exchange init-3 1 1 0))
;               (update-4 (exchange-update update-1 1 1 0))
;               (update-5 (exchange-update update-2 1 1 0))
;               (update-6 (exchange-update update-3 1 1 0)))
;          (append*(list (list init-1 update-1))
;                  (list (list init-2 update-2))
;                  (list (list init-3 update-3))
;                  (if (not ())(list (list init-4 update-4))
;                (list (list init-5 update-5))
;                (list init-6 update-6))
;      )  
        
      

      ; (rotate-update-r (update 0 0 1)) => (update 1 0 0)
;      (define (rotate-update-r update-method)
;        
;        (lambda (pos)
;          (let* ((new-pos (rotate-l pos))
;                 (updated-new-pos (update-method new-pos))
;                 (updated-pos (rotate-r updated-new-pos)))
;            updated-pos)))
;
;
;      ; (exchange-update (update 1 0 -1) 1 0 1) => (update -1 0 1)  
;      (define (exchange-update update-method x y z)
;        ;; only two must be 1 and the remaining must be 0
;        
;        (lambda (pos)
;            (let* ((new-pos (exchange pos x y z))
;                   (updated-new-pos (update-method new-pos))
;                   (updated-pos (exchange updated-new-pos x y z)))
;              updated-pos))))  
    
  