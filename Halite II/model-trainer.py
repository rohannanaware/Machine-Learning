import keras
from keras.models import Sequential
from keras.layers import Dense, Dropout, Activation
from keras.models import load_model
import random
from tqdm import tqdm
import numpy as np

batch_size = 128
epochs = 10
test_size = 5000

in_model = 'model_checkpoint_{}_batch_{}_epochs.h5'.format(0,0)
out_model = 'model_checkpoint_{}_batch_{}_epochs.h5'.format(batch_size, epochs)

load_prev_model = False

if load_prev_model:
    print("Loading model: ", in_model)
    model = load_model(in_model)
else:
    print("starting fresh!")


print("Reading input")
with open("train.in","r") as f:
    train_in = f.read().split('\n')
    train_in = [eval(i) for i in tqdm(train_in[:-1])]
    print("done train in")
    
print("Reading output")
with open("train.out","r") as f:
    train_out = f.read().split('\n')
    train_out = [eval(i) for i in tqdm(train_out[:-1])]
    print("done train out")

attack_enemy = []
mine_our_planet = []
mine_empty_planet = []

print("balancing data...")
for n, _ in tqdm(enumerate(train_in)):
    input_layer = train_in[n]
    output_layer = train_out[n]

    if output_layer == [1,0,0]:
        attack_enemy.append([input_layer, output_layer])
    elif output_layer == [0,1,0]:
        mine_our_planet.append([input_layer, output_layer])
    elif output_layer == [0,0,1]:
        mine_empty_planet.append([input_layer, output_layer])

print(len(attack_enemy), len(mine_our_planet), len(mine_empty_planet))
shortest = min(len(attack_enemy), len(mine_our_planet), len(mine_empty_planet))

random.shuffle(attack_enemy)
random.shuffle(mine_our_planet)
random.shuffle(mine_empty_planet)

attack_enemy = attack_enemy[:shortest]
mine_our_planet = mine_our_planet[:shortest]
mine_empty_planet = mine_empty_planet[:shortest]

print(len(attack_enemy), len(mine_our_planet), len(mine_empty_planet))

all_choices = attack_enemy + mine_our_planet + mine_empty_planet
random.shuffle(all_choices)

train_in = []
train_out = []

print("rebuilding training data...")
for x,y in tqdm(all_choices):
    train_in.append(x)
    train_out.append(y)

np.save("train_in.npy", train_in)
np.save("train_out.npy", train_out)

train_in = np.load("train_in.npy")
train_out = np.load("train_out.npy")

print('train_in:',len(train_in))

x_train = train_in[:-test_size]
y_train = train_out[:-test_size]

x_test = train_in[-test_size:]
y_test = train_out[-test_size:]

print('Building model...')
if not load_prev_model:
    model = Sequential()
    model.add(Dense(256, input_shape=(len(train_in[0]),)))
    model.add(Activation('relu'))
    model.add(Dropout(0.5))
    model.add(Dense(256, input_shape=(256,)))
    model.add(Activation('relu'))
    model.add(Dropout(0.5))
    model.add(Dense(len(train_out[0])))
    model.add(Activation('softmax'))

    model.compile(loss='categorical_crossentropy',
                  optimizer='adam',
                  metrics=['accuracy'])

history = model.fit(x_train, y_train,
                    batch_size=batch_size,
                    epochs=epochs,
                    verbose=1,
                    validation_split=0.1)

score = model.evaluate(x_test, y_test,
                       batch_size=batch_size, verbose=1)

model.save(out_model)
print("Model saved to:",out_model)
print('Test score:', score[0])
print('Test accuracy:', score[1])
