module pfft.common;

template TypeTuple(A...)
{
    alias A TypeTuple;
}

static if(false && is(typeof({ import gcc.attribute; }))) //disable this for now
{
    public import gcc.attribute;
    enum always_inline = attribute("always_inline");
    enum hot = attribute("hot");
}
else
{
    alias always_inline = TypeTuple!();
    alias hot = TypeTuple!();
}

template st(alias a){ enum st = cast(size_t) a; }

struct Tuple(A...)
{
    A a;
    alias a this;
}

void swap(T)(ref T a, ref T b)
{
    auto aa = a;
    auto bb = b;
    b = aa;
    a = bb;
}

template ints_up_to(int n, T...)
{
    static if(n)
    {
        alias ints_up_to!(n-1, n-1, T) ints_up_to;
    }
    else
        alias T ints_up_to;
}

template powers_up_to(int n, T...)
{
    static if(n > 1)
    {
        alias powers_up_to!(n / 2, n / 2, T) powers_up_to;
    }
    else
        alias T powers_up_to;
}

template RepeatType(T, int n, R...)
{
    static if(n == 0)
        alias R RepeatType;
    else
        alias RepeatType!(T, n - 1, T, R) RepeatType;
}

version(LDC)
    pragma(LDC_intrinsic, "llvm.prefetch")
        void llvm_prefetch(void*, int, int, int);

@always_inline
void prefetch(bool isRead, bool isTemporal)(void* p)
{
    version(GNU)
    {
        import gcc.builtins;
        __builtin_prefetch(p, isRead ? 0 : 1, isTemporal ? 3 : 0);
    }
    else version(LDC)
        llvm_prefetch(p, isRead ? 0 : 1, isTemporal ? 3 : 0, 1);
}

@always_inline
void prefetch_array(int len, TT)(TT* a)
{
    enum elements_per_cache_line = 64 / TT.sizeof;

    foreach(i; ints_up_to!(len / elements_per_cache_line))
        prefetch!(true, true)(a + i * elements_per_cache_line);
}
