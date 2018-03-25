#lang racket

;;; a demo of a function that check of a winning position is formed

;;; Since, in the current turn, a line can only be formed, if it includes
;;; the last played position, we take this position, and check from the
;;; corresponding beginning of every such line. 

(define board
  '(((1 1 1 1) (0 0 0 0) (0 0 0 0) (0 0 0 0))
  ((0 0 0 0) (0 0 0 0) (0 0 0 0) (0 0 0 0))
  ((0 0 0 0) (0 0 0 0) (0 0 0 0) (0 0 0 0))
  ((0 0 0 0) (0 0 0 0) (0 0 0 0) (0 0 0 0))))
; unset state is 0; other states are -1 and 1.
(define last-played-pos '(0 0 0))

(define (get-value pos)
  ;; pos - a list of x y z coordinates, in that order
  (list-ref (list-ref (list-ref board (caddr pos)) (cadr pos)) (car pos)))

(define (win? player)
  ; returns #t if a player has won.

  (define n 3) ; increase n to increase size of board (board-size - 1)
  
  (define line-found #f)
  (define lpp last-played-pos) ; abbreviation
  
  (define (get-line init-update)
    (define init (car init-update))
    (define update (cadr init-update))
    (while/list border-not-reached? update init))

  (define (in-a-line? l)
    ; takes in a list of coordinates and checks if they form a complete line
    ; currently does not check if the position is unset.
    (and (apply = (map get-value l)) (not (= 0 (get-value (car l))))))
  
  (define (border-not-reached? pos)
    ; Returns #t if pos is an invalid (in a greater sense) coordinate
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
               (if (= n (+ x z)) (list (list (list n y 0) (update -1 0 1))) '())))
    
    (define (gen-body-diag)
      (append* (if (= x y z) (list (list (list 0 0 0) (update 0 0 0))) '())
               (if (and (= x y) (= n (+ x z)))
                   (list (list (list 0 0 3) (update 1 1 -1))) '())
               (if (and (= x z) (= n (+ x y)))
                   (list (list (list 0 3 0) (update 1 -1 1))) '())
               (if (and (= z y) (= n (+ x z)))
                   (list (list (list 3 0 0) (update -1 1 1))) '())))
    
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
    (if line-found
        (if (= player 1) (displayln "Player 1 won") (displayln "Player 2 won"))
        line-found)
    line-found)
    

  (helper))
      
                
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
  