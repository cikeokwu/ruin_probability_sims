from simc import simulate_effect
import os
from multiprocessing import Pool


P = 1
AVG_INCOME = 100
AVG_SHOCK_TIME = 100
MAX_SHOCK_SIZE = 100
NUM_AGENTS = 2


def simulate_effect_wrapper(params):
    num_trial = params[0]
    diff = params[1]
    # if num_trial % 50 == 0:
    #     print(f"On trial {num_trial} with diff of {diff} ")
    return simulate_effect(P, AVG_INCOME, AVG_SHOCK_TIME, MAX_SHOCK_SIZE, NUM_AGENTS, diff, num_trial)

def get_effects_pooled(num_trials, p, avg_income, avg_shock_time, max_shock_size, num_agents=2):
    """
    :param num_trials: number of simulations to run
    :param p: proportion of income that should be given to the savings circle
    :param avg_income:  average income per agent
    :param avg_shock_time: average number of shocks per time step
    :param max_shock_size: maximum shock size per time step (uniform distribution between 0 and max size)
    :param num_agents:  number of agents to run the simulation for
    :return: Two dimensional array the first index is for varied income and second index is for varying shocks:
            Each array has the ruin times for each run and the shortfall that would have been needed to avoid ruin.
    """
    global P
    global AVG_INCOME
    global AVG_SHOCK_TIME
    global MAX_SHOCK_SIZE
    global NUM_AGENTS
    global DIFF
    P = p
    AVG_INCOME = avg_income
    AVG_SHOCK_TIME = avg_shock_time
    MAX_SHOCK_SIZE = max_shock_size
    NUM_AGENTS = num_agents
    print(f"Running with paramters p = {P}, average income = {AVG_INCOME}, average shock times = {AVG_SHOCK_TIME}, max shock size = {MAX_SHOCK_SIZE}")
    num_processes = os.cpu_count() * 2
    print(f"Number of processes: {num_processes}")
    params = [0]*num_trials + [1]*num_trials + [2]*num_trials + [3]*num_trials
    args = zip(range(4*num_trials), params)

    with Pool(processes=num_processes) as pool:
        results = pool.map(simulate_effect_wrapper, args)
        pool.close()
        pool.join()


    return [results[x] for x in range(num_trials)], [results[x] for x in range(num_trials,2*num_trials)], [results[x] for x in range(2*num_trials,3*num_trials)], [results[x] for x in range(3*num_trials,4*num_trials)]
