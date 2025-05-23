use criterion::{black_box, criterion_group, criterion_main, Criterion};
use mathplz::DNASequence;
use rand::seq::SliceRandom;

fn bench_dna_sequence(c: &mut Criterion) {
    let mut group = c.benchmark_group("DNASequence");

    for size in [100, 1000, 10000].iter() {
        let bases = ['A', 'T', 'C', 'G'];
        let sequence: String = (0..*size)
            .map(|_| {
                let mut rng = rand::thread_rng();
                *bases.choose(&mut rng).unwrap()
            })
            .collect();

        group.bench_function(&format!("create_{}", size), |b| {
            b.iter(|| black_box(DNASequence::new(&sequence).unwrap()))
        });
    }

    group.finish();
}

criterion_group!(benches, bench_dna_sequence);
criterion_main!(benches);
