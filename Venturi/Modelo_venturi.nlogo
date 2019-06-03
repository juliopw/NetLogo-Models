;Simulação de um Tubo de Venturi

;Trabalho desenvolvido por

;Julio Patron Witwytzkyj
;Symon Nickson da Silva Santana
;Victor Miguel Canto

;Durante a disciplina de Modelagem de Sistemas, do curso de
;Engenharia Mecânica da Universidade do Vale do Itajaí


;______________________________________________________________________________

;A cor dos patches no centro do tubo tem o código 87.1.

;
;(0, 150)_______________________________________________________(1000, 150)
;|                                                              |
;|                                                              |
;|                                                              |
;|                                                              |
;(0, 0)                Sistema de coordenadas                   (1000, 0)
;|                                                              |
;|                                                              |
;|                                                              |
;(0, -150)______________________________________________________(1000, -150)


extensions[ bitmap ]

;Variáveis globais
globals[
  ;Variável que guarda a vazão total.
  vazao

  ;Variáveis que guardam a área das seções de maior (1) e menor (2) diâmetro.
  area1
  area2

  ;Variáveis que guardam as coordenadas da rampa (apenas no fluxo sem colisão).
  inicio_rampa_1_x
  fim_rampa_1_x
  inicio_rampa_1_y_max
  fim_rampa_1_y_max

  ;variáveis que guardam a média de deslocamento em cada seção do tubo
  deslocamento_secao_1
  deslocamento_secao_2

  colisoes_secao_1
  colisoes_secao_2

  quantidade-particulas
]

;As partículas de água são do tipo água.
breed [ aguas agua ]

;Essas partículas possuem:
aguas-own
[
  ;Velocidade da partícula
  velocidade

  ;Variável auxiliar para que o loop não continue direcionando as partículas (apenas no fluxo sem colisão).
  direcionado

  ;Variáveis auxiliares para medida do deslocamento no sentido da coordenada x.
  posicao-antiga
  posicao-atual

  ;Variável que guarda o deslocamento da partícula.
  deslocamento

  ;Variável auxiliar para indicar colisão com paredes
  numero-colisoes-paredes
]

to setup
  ;Limpa a simulação
  clear-all


  ;Chama a função que verifica se o diâmetro maior é maior que o diâmetro menor.
  verifica_diametros

  ;Predefinição de variáveis (unidades em mm).
  set var_C_materiais "Personalizado"
  set diametro_maior 44
  set diametro_menor 25
  set diferenca_pressao 40

  ;Coordenadas da rampa de entrada do tubo. Obtidas através de clique com botão direito.
  set inicio_rampa_1_x 300
  set fim_rampa_1_x 667
  set inicio_rampa_1_y_max 78
  set fim_rampa_1_y_max 52

  ;O fundo da simulação é branco
  ask patches [set pcolor white]

  if tipo-de-tubo = "Venturi" [
    ;Importa o desenho do tubo de venturi
    import-pcolors "venturi.png"
  ]

  if tipo-de-tubo = "Venturi Angulos Retos" [
    ;Importa o desenho do tubo de venturi
    import-pcolors "angulosretos.png"
  ]

  ;Caso o usuário deseje que as paredes do tubo sejam pretas, pinta tudo o que não for 87.1 de preto
  if paredes_pretas = true [ask patches with [pcolor != 87.1] [ set pcolor black ]]

  ;pinta de verde e vermelho as cores relacionadas às seções 1 e 2 (diâmetro maior e diâmetro menor)
  pinta_cores_secoes

  ;As partículas devem ser circulares
  set-default-shape turtles "circle"

  ;Zera o contador de ticks
  reset-ticks
end

;Loop infinito
to go
  ;Chama a função que verifica se o diâmetro maior é maior que o diâmetro menor.
  verifica_diametros

  ;Chama a função que Calcula a vazão a partir de uma equação
  ;obtida através da aplicação da equação de Bernoulli ao tubo
  ;de Venturi.
  calcula_vazao

  ;Cria as partículas aleatoriamente mas dentro do tubo na coordenada Y e na posição 2 na coordenada X
  cria_particulas

  ;Para cada turtle
  ask aguas [

    ;A partícula não escreve seu caminho (pen-down para que escreva)
    pen-up

    ;Caso a chave de seleção do tipo de fluxo esteja ligada, mover por colisão
    if fluxo_por_colisao = true [
      ;Chama a função que move a partícula por colisão
      mover_colidir
    ]

    ;Caso contrário, mover por direcionamento
    if fluxo_por_colisao = false [
      ;Chama a função que move a partícula por direcionamento
      mover_direcionado
    ]

    ;Chama a função que calcula o deslocamento de cada partícula
    calcula_deslocamento_particula
  ]

  ;Chama a função que calcula a média do deslocamento em cada seção do tubo
  calcula_media_deslocamento

  ;Chama a função que calcula a média de colisões com paredes em cada seção do tubo
  calcula_media_colisoes_paredes



  ;Conta uma unidade de tempo
  tick
end


;Função que move a partícula por colisão
to mover_colidir

  move_Y_particulas_que_escapam

  ;Verifica se a partícula deve ser refletida caso
  ;esteja antes do inicio do tubo ou morra caso
  ;esteja fora do tubo
  mata_ou_reflete_particulas

  ;Se existe qualquer outra partícula num raio especificado, colidir com a partícula
  if any? other aguas-on patches in-radius distancia_colisao [
    ;Define a direção da partícula como 90 (da esquerda para a direita) + um ângulo aleatório definido por angulo_colisao
    set heading (90 - (angulo_colisao / 2)  + random angulo_colisao)
  ]

  ;Verifica se a partícula deve ser refletida caso
  ;esteja antes do inicio do tubo ou morra caso
  ;esteja fora do tubo
  mata_ou_reflete_particulas


  if ([pcolor] of patch-at dy -3 != 87.1 and [pcolor] of patch-at dy 3 != 87.1) [
    aleatorio
  ]

  ;Verifica se há uma parede acima da partícula
  if ([pcolor] of patch-at dy 3 != 87.1) [
    ;Se sim, muda sua direção levemente para baixo
    set heading (120)

    ;Aumenta o contador de colisões com as paredes
    set numero-colisoes-paredes numero-colisoes-paredes + 1
  ]

  ;Verifica se há uma parede abaixo da partícula
  if ([pcolor] of patch-at dy -3 != 87.1) [
    ;Se sim, muda sua direção levemente para cima
    set heading (60)

    ;Aumenta o contador de colisões com as paredes
    set numero-colisoes-paredes numero-colisoes-paredes + 1
  ]

  if any? aguas [set quantidade-particulas count aguas]

  ;define a velocidade de cada partícula a partir da vazão e coordenada Y
  ;criando assim o perfil parabólico observado nesse tipo de fluxo
  set velocidade  0.4 * ( vazao / (pi * ((20) / 1000) ^ 2 )) * (1 - (abs (ycor ^ 2.0) / (85 ^ 2.0)))

  ;Avança nos patches a velocidade calculada anteriormente
  fd velocidade

  ;Verifica se a partícula deve ser refletida caso
  ;esteja antes do inicio do tubo ou morra caso
  ;esteja fora do tubo
  mata_ou_reflete_particulas

end


;Função que move a partícula por direcionamento
to mover_direcionado

  move_Y_particulas_que_escapam

  ;Verifica se a partícula deve ser refletida caso
  ;esteja antes do inicio do tubo ou morra caso
  ;esteja fora do tubo
  mata_ou_reflete_particulas

  ;O tubo é dividido em 5 partes, onde cada parte é caracterizada pela inclinação de suas paredes.
  ;Cada parte tem uma equação que governa seu direcionamento e velocidade

  ;Na parte 1 do tubo
  if pxcor > 0 and pxcor <= inicio_rampa_1_x [

    ;Mantem velocidade em Y e varia velocidade em X conforme vazão e área
    setxy (pxcor + (vazao / area1) / 100) pycor

    ;A variável auxiliar direcionado é desligada
    set direcionado 0

    ;A velocidade da partícula é calculada
    set velocidade  0.2 * ((1 + 300 / 1000)^ 2 ) * ( vazao / (pi * (20 / 1000) ^ 2 )) * (1 - (abs (ycor ^ 2.0) / (100.0 ^ 2.0)))
  ]

  ;Na parte 2 do tubo, na rampa de entrada
  if pxcor > inicio_rampa_1_x and pxcor <= fim_rampa_1_x [

    ;
    if direcionado = 0 [

      set heading (90 + 0.08 * pycor)
      set direcionado 1
      set velocidade  0.3 * ((1 + xcor / 1000) ^ 2 ) * ( vazao / (pi * (20 / 1000) ^ 2 )) * (1 - (abs (ycor ^ 2.0) / (100.0 ^ 2.0)))
    ]
  ]

  ;Na parte 3 do tubo, diâmetro menor do tubo
  if pxcor > fim_rampa_1_x and pxcor <= 837 [

    set heading 90
    set direcionado 0
    set velocidade  0.2 * ((1 + (fim_rampa_1_x - inicio_rampa_1_x) / 1000) ^ 2 ) * ( vazao / (pi * (20 / 1000) ^ 2 )) * (1 - (abs (ycor ^ 2.0) / (100.0 ^ 2.0)))
  ]

  ;Na parte 4 do tubo, saída do tubo
  if pxcor > 837 and pxcor <= 965 [

    if direcionado = 0 [
      set heading (90 - 0.4 * pycor)
      set direcionado 1
      set velocidade  0.3 * ((1 - xcor / 20000) ^ 2 )  * ( vazao / (pi * (20 / 1000) ^ 2 )) * (1 - (abs (ycor ^ 2.0) / (100.0 ^ 2.0)))
    ]
  ]

  ;Na parte 5 do tubo, parte final de saída
  if pxcor > 965 [
    set heading 90
    set velocidade 0.2 * ((1 + 300 / 1000)^ 2 ) * ( vazao / (pi * (20 / 1000) ^ 2 )) * (1 - (abs (ycor ^ 2.0) / (100.0 ^ 2.0)))
  ]

  ;Avança nos patches a velocidade calculada anteriormente
  fd velocidade

  ;Verifica se a partícula deve ser refletida caso
  ;esteja antes do inicio do tubo ou morra caso
  ;esteja fora do tubo
  mata_ou_reflete_particulas
end

;Verifica se a partícula deve ser refletida caso
;esteja antes do inicio do tubo ou morra caso
;esteja fora do tubo
to mata_ou_reflete_particulas

  ;Caso as bolinhas comecem a escapar é interessante que sejam apagadas
  if apagar_bolinhas_que_escapam = true [
    ;Partículas que não estejam num patch dentro do tubo (cor 87.1) morrem
    if pcolor != 87.1 [ die ]
  ]

  ;Se a partícula tenta voltar pelo início do tubo, inverter sua direção
  if (pxcor = min-pxcor - 2) [ set heading (- heading) ]

  ;Se a partícula ainda assim consegue passar pela coordenada de início do tubo - 2
  ;Particula morre de forma trágica
  if (pxcor <= min-pxcor - 5) [ die ]

  ;Se a partícula chega ao fim do tubo
  ;Particula morre de forma trágica
  if (pxcor >= max-pxcor - 5) [ die ]

  if (pycor >= max-pycor - 5) [ die ]

  if (pycor <= min-pycor + 5) [ die ]

end

to move_Y_particulas_que_escapam
  if ([pcolor] of patch-at dy 1 != 87.1 and [pcolor] of patch-at dy -1 != 87.1) [
    aleatorio
  ]
end

;Gera coordenadas aleatórias.
to aleatorio
  setxy xcor random-ycor
  ;Se não está dentro do tubo.
  if pcolor != 87.1
    ;Tenta de novo.
    [ aleatorio ]
end

;Verifica se o diâmetro maior é maior que o diâmetro menor.
to verifica_diametros

  ;Se o diâmetro da seção maior é menor ou igual ao diâmetro da seção menor
  ;o programa deve parar e mostrar um aviso, já que o efeito de venturi só ocorre quando há
  ;essas diferenças no diâmetro
  if diametro_maior <= diametro_menor [

    ;Envia mensagem de aviso
    user-message (word "O diâmetro menor (d) não pode ser maior que o diâmetro maior (D).")

    ;Redefine o diâmetro maior para que o programa possa continuar rodando
    set diametro_maior diametro_menor + 5
  ]

end

;Calcula a vazão a partir de uma equação obtida através
;da aplicação da equação de Bernoulli ao tubo de Venturi.
to calcula_vazao

  ;Calcula o valor de área das seções 1 e 2 do tubo de Venturi
  set area1 pi * ( ( diametro_maior / (2 * 1000)) ^ 2 )
  set area2 pi * ( ( diametro_menor / (2 * 1000)) ^ 2 )

  ;Define o valor do coeficiente de perda de carga
  if var_C_materiais = "Aço" [set var_C 0.68]
  if var_C_materiais = "Aluminio" [set var_C 0.75]
  if var_C_materiais = "PVC" [set var_C 0.8]
  if var_C_materiais = "Nylon usinado" [set var_C 0.6]
  if var_C_materiais = "Personalizado" []

  ;Calcula a vazão a partir da equação, com as devidas conversões de
  ;[mm] para [m] (/ 1000) e de
  ;[m3/s] para [m3/min] (* 60)
  set vazao ((2 * 9.81 * (diferenca_pressao / 1000)) ^ (1 / 2)) * (area1 / ((((area1 / area2) ^ 2 ) - 1) ^ (1 / 2))) * var_C * 60

end

;Cria as partículas no início do tubo de Venturi
to cria_particulas

  ;Cria uma certa quantidade de partículas
  ;dependendo do valor de vazão
  create-aguas vazao * var-particulas-criadas [

    ;Pinta partículas de acordo com a cor escolhida
    if cor_particulas = "Azul" [ set color blue ]
    if cor_particulas = "Preto" [ set color black ]
    if cor_particulas = "Aleatorio" [ set color random 200 ]

    ;Define coordenada Y aleatória
    aleatorio

    ;Define coordenada inicial X no início do tubo
    set xcor 2

    ;Define o tamanho da partícula
    set size tamanho_particula

    ;Caso a chave de seleção do tipo de fluxo esteja ligada, mover por colisão
    if fluxo_por_colisao = true [

      ;Define a direção inicial de movimento da esquerda para a direita
      set heading (90 - (angulo_colisao / 2)  + random angulo_colisao)
    ]

    if fluxo_por_colisao = false [

      ;Define a direção inicial de movimento da esquerda para a direita
      set heading (90)
    ]

  ]

end

;Calcula o deslocamento na direção da coordenada X para cada partícula
to calcula_deslocamento_particula
  ;Guarda a posição atual
  set posicao-atual pxcor

  ;Calcula o deslocamento em X da partícula
  set deslocamento (posicao-atual - posicao-antiga)

  ;Guarda a posição anterior para o próximo cálculo
  set posicao-antiga posicao-atual
end

;Para a seção 1, a partir da coordenada 30 em X e até o início da rampa de entrada
;calcula a média do deslocamento de todas as partículas que estão nessa região.
;Para a seção 2, a partir da coordenada de fim da rampa de entrada em X e até a coordenada 837
;calcula a média do deslocamento de todas as partículas que estão nessa região
to calcula_media_deslocamento

  ;Inicialmente verifica se existe alguma partícula na região para evitar erros
  if any? aguas with [pxcor > 30 and pxcor < inicio_rampa_1_x] [set deslocamento_secao_1 mean [deslocamento] of aguas with [pxcor > 30 and pxcor < inicio_rampa_1_x]]

  ;Inicialmente verifica se existe alguma partícula na região para evitar erros
  if any? aguas with [pxcor > fim_rampa_1_x and pxcor < 837] [set deslocamento_secao_2 mean [deslocamento] of aguas with [pxcor > fim_rampa_1_x and pxcor < 837]]
end

to calcula_media_colisoes_paredes
  ;Inicialmente verifica se existe alguma partícula na região para evitar erros
  if any? aguas with [pxcor > (inicio_rampa_1_x - 170) and pxcor < inicio_rampa_1_x] [set colisoes_secao_1 mean [numero-colisoes-paredes] of aguas with [pxcor > 30 and pxcor < inicio_rampa_1_x]]

  ;Inicialmente verifica se existe alguma partícula na região para evitar erros
  if any? aguas with [pxcor > fim_rampa_1_x and pxcor < 837] [set colisoes_secao_2 mean [numero-colisoes-paredes] of aguas with [pxcor > fim_rampa_1_x and pxcor < 837]]


  if any? aguas with [pxcor > inicio_rampa_1_x and pxcor < fim_rampa_1_x] [ask aguas with [pxcor > inicio_rampa_1_x and pxcor < fim_rampa_1_x] [set numero-colisoes-paredes 0]]
end

;pinta de verde e vermelho as cores relacionadas às seções 1 e 2 (diâmetro maior e diâmetro menor)
to pinta_cores_secoes
  ;pinta de verde a primeira seção
  ask patches with [pycor >= 100 and pycor <= 108 and pxcor <= 300] [set pcolor green]

  ;pinta de vermelho a segunda seção
  ask patches with [pycor >= 100 and pycor <= 108 and pxcor >= 667 and pxcor <= 837] [set pcolor red]
end
@#$#@#$#@
GRAPHICS-WINDOW
351
309
1360
539
-1
-1
1.0
1
12
1
1
1
0
0
0
1
0
1000
-110
110
1
1
1
Tempo (ticks)
60.0

BUTTON
179
10
334
43
Iniciar
go
T
1
T
OBSERVER
NIL
I
NIL
NIL
1

BUTTON
10
10
173
43
Configurar
setup
NIL
1
T
OBSERVER
NIL
C
NIL
NIL
1

SLIDER
8
52
333
85
diametro_maior
diametro_maior
1
100
92.0
1
1
mm
HORIZONTAL

SLIDER
9
93
334
126
diametro_menor
diametro_menor
1
100
73.0
1
1
mm
HORIZONTAL

PLOT
345
10
588
269
Vazão através de Bernoulli
ticks
Vazão (m3/s)
0.0
100.0
0.0
0.002
true
false
"" "set-plot-x-range (ticks - 200) ticks"
PENS
"Vazão" 1.0 0 -13345367 true "" "plot vazao"

SLIDER
9
136
334
169
diferenca_pressao
diferenca_pressao
0
200
40.0
1
1
mmH2O
HORIZONTAL

SLIDER
9
178
333
211
var_C
var_C
0
1
0.61
0.01
1
NIL
HORIZONTAL

MONITOR
158
220
333
269
Vazão (m3/min)
vazao
6
1
12

CHOOSER
8
222
146
267
var_C_materiais
var_C_materiais
"Aço" "Aluminio" "PVC" "Nylon usinado" "Personalizado"
4

SWITCH
7
276
333
309
fluxo_por_colisao
fluxo_por_colisao
0
1
-1000

SLIDER
7
314
332
347
angulo_colisao
angulo_colisao
0
360
90.0
5
1
NIL
HORIZONTAL

SLIDER
7
353
332
386
distancia_colisao
distancia_colisao
0
20
3.0
1
1
NIL
HORIZONTAL

PLOT
1012
10
1374
269
Velocidade média das partículas por ticks
ticks
velocidade media (patches/tick)
0.0
10.0
0.0
10.0
true
true
"" "set-plot-x-range (ticks - 200) ticks\n;set-plot-y-range (deslocamento_secao_1 - 3) (deslocamento_secao_2 + 3)"
PENS
"Área maior" 1.0 0 -13840069 true "" "plot deslocamento_secao_1"
"Área menor" 1.0 0 -2674135 true "" "plot deslocamento_secao_2"

PLOT
595
10
792
269
Área da tubulação
Ticks
Área (m2/s)
0.0
0.1
0.0
0.001
true
false
"" "set-plot-x-range (ticks - 200) ticks\n;set-plot-y-range (area2 - (area2 + 0.001) / 5) (area1 + (area1 + 0.001) / 5)"
PENS
"Area 1" 1.0 0 -13840069 true "" "plot area1"
"Area 2" 1.0 0 -2674135 true "" "plot area2"

SWITCH
7
393
332
426
apagar_bolinhas_que_escapam
apagar_bolinhas_que_escapam
0
1
-1000

SWITCH
9
439
151
472
paredes_pretas
paredes_pretas
1
1
-1000

CHOOSER
8
486
332
531
cor_particulas
cor_particulas
"Azul" "Preto" "Aleatorio"
2

SLIDER
8
575
333
608
var-particulas-criadas
var-particulas-criadas
0
50000
806.0
1
1
particulas * vazão / tick
HORIZONTAL

SLIDER
8
537
332
570
tamanho_particula
tamanho_particula
1
25
4.0
1
1
px
HORIZONTAL

PLOT
798
10
1007
269
Colisões com paredes
ticks
Colisões
0.0
1.0
0.0
1.0
true
false
"" "set-plot-x-range (ticks - 200) ticks"
PENS
"Área maior" 1.0 0 -13840069 true "" "plot colisoes_secao_1"
"Área menor" 1.0 0 -2674135 true "" "plot colisoes_secao_2"

CHOOSER
161
433
332
478
tipo-de-tubo
tipo-de-tubo
"Venturi" "Venturi Angulos Retos"
0

MONITOR
351
561
520
610
Quantidade de partículas
quantidade-particulas
17
1
12

@#$#@#$#@
## O QUE É?

A simulação mostra os valores de vazão numa tubulação 
(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="var_C">
      <value value="0.78"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var-particulas-criadas">
      <value value="4097"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var_C_materiais">
      <value value="&quot;Personalizado&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paredes_pretas">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diametro_maior">
      <value value="44"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamanho_particula">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="angulo_colisao">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="apagar_bolinhas_que_escapam">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distancia_colisao">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fluxo_por_colisao">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cor_particulas">
      <value value="&quot;Azul&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diametro_menor">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diferenca_pressao">
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
