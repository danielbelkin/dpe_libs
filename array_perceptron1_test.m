data = num2cell([1 0 0 1; 0 1 1 0]',1);

labels = [1 2];

net = array_perceptron1([4 2]);
%%
nreps = 10;
rate = 5;
net = net.train(data, labels, rate, nreps);
%%
[err, stats] = net.test(data, labels);



%%
V_batch_reset = ones(128, 64) * 1.8;
V_batch_gate_reset = ones(128,64) * 5;

net.array.batch_reset(V_batch_reset, V_batch_gate_reset);

%
[~, G_read] = net.array.batch_read(V_read, 2);
imagesc(G_read(1:4, 1:2)); colorbar;
